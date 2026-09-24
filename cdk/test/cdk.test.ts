import * as fs from 'fs';

import * as cdk from 'aws-cdk-lib';
import { Match, Template } from 'aws-cdk-lib/assertions';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as sns from 'aws-cdk-lib/aws-sns';

import { Config } from '../lib/config';
import { EcsStack } from '../lib/ecs-stack';

const config: Config = JSON.parse(fs.readFileSync('config/testi.json', 'utf8'));

const buildEcsStackTemplate = (): Template => {
  const app = new cdk.App();
  const env = { account: '111122223333', region: 'eu-west-1' };

  // Kevyet apupinot EcsStackin riippuvuuksille. Verkko ja tietokanta ovat eri pinoissa
  // kuten oikeassa sovelluksessa: EcsStack lisää rooleja ja ingress-sääntöjä
  // tietokantapinon resursseihin, joten yhteen pinoon koottuna syntyisi riippuvuussykli.
  const network = new cdk.Stack(app, 'TestNetworkStack', { env });
  const database = new cdk.Stack(app, 'TestDatabaseStack', { env });
  const support = new cdk.Stack(app, 'TestSupportStack', { env });
  const vpc = new ec2.Vpc(network, 'TestVpc');

  const ecsStack = new EcsStack(app, `${config.environment}-EcsStack`, {
    accountId: env.account,
    config,
    env,
    vpc,
    // Oikea klusteri eikä importattu: EcsStack muokkaa klusterin associatedRoles-kenttää
    // defaultChildin kautta, jota importatulla klusterilla ei ole.
    auroraCluster: new rds.DatabaseCluster(database, 'TestAuroraCluster', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.of(
          config.aurora.version.full,
          config.aurora.version.major
        ),
      }),
      vpc,
      writer: rds.ClusterInstance.serverlessV2('writer'),
    }),
    auroraSecurityGroup: ec2.SecurityGroup.fromSecurityGroupId(
      database,
      'TestAuroraSecurityGroup',
      'sg-12345678'
    ),
    // mutable: false pitää EcsStackin myöntämät oikeudet pois apupinosta, jolloin
    // pinojen välille ei synny riippuvuussykliä.
    githubActionsDeploymentRole: iam.Role.fromRoleArn(
      support,
      'TestDeploymentRole',
      `arn:aws:iam::${env.account}:role/test-deployment-role`,
      { mutable: false }
    ),
    ecsImageTag: 'test-tag',
    slackAlarmIntegrationSnsTopic: new sns.Topic(support, 'TestSlackAlarmTopic'),
  });

  return Template.fromStack(ecsStack);
};

describe('EcsStack ECS-tehtävien valvonta', () => {
  // Kontin käynnistymisen valvontaa ei voi tehdä lokisuodattimilla, koska kontti ei
  // ehdi kirjoittaa lokiriviä lainkaan jos käynnistys epäonnistuu.
  const tasks = [
    { name: 'dbt-task', description: 'DBT-ajo' },
    { name: 'lampi-siirtaja-task', description: 'Ovaran tietojen siirto Lampeen' },
  ];

  test.each(tasks)(
    '$name hälyttää kun kontin käynnistys epäonnistuu',
    ({ name, description }) => {
      buildEcsStackTemplate().hasResourceProperties('AWS::Events::Rule', {
        Name: `${config.environment}-${name}-failed-to-start-rule`,
        Description: `${description}: kontin käynnistys epäonnistui`,
        EventPattern: Match.objectLike({
          source: ['aws.ecs'],
          'detail-type': ['ECS Task State Change'],
          detail: Match.objectLike({
            lastStatus: ['STOPPED'],
            stopCode: ['TaskFailedToStart'],
          }),
        }),
      });
    }
  );

  test.each(tasks)(
    '$name hälyttää kun kontti päättyy virhekoodiin',
    ({ name, description }) => {
      buildEcsStackTemplate().hasResourceProperties('AWS::Events::Rule', {
        Name: `${config.environment}-${name}-exited-nonzero-rule`,
        Description: `${description}: kontti päättyi virheeseen`,
        EventPattern: Match.objectLike({
          source: ['aws.ecs'],
          'detail-type': ['ECS Task State Change'],
          detail: Match.objectLike({
            lastStatus: ['STOPPED'],
            stopCode: ['EssentialContainerExited'],
            // Ilman exitCode-ehtoa hälytys lähtisi myös onnistuneesta ajosta.
            containers: { exitCode: [{ 'anything-but': [0] }] },
          }),
        }),
      });
    }
  );

  test('jokainen tehtävä valvoo omaa task definition -perhettään', () => {
    const template = buildEcsStackTemplate();
    const rules = template.findResources('AWS::Events::Rule');

    const taskGroups = Object.values(rules)
      .filter((rule) => String(rule.Properties.Name).includes('-task-'))
      .map((rule) => rule.Properties.EventPattern.detail.group[0]);

    expect(taskGroups).toHaveLength(4);
    taskGroups.forEach((group) => expect(group).toMatch(/^family:/));
    // Kaksi eri perhettä, molemmille kaksi sääntöä.
    expect(new Set(taskGroups).size).toBe(2);
  });

  test('jokainen sääntö lähettää Chatbotin custom notification -viestin', () => {
    const rules = buildEcsStackTemplate().findResources('AWS::Events::Rule');

    const taskRules = Object.values(rules).filter((rule) =>
      String(rule.Properties.Name).includes('-task-')
    );
    expect(taskRules).toHaveLength(4);

    taskRules.forEach((rule) => {
      const transformer = rule.Properties.Targets[0].InputTransformer;
      expect(transformer).toBeDefined();

      // InputTemplate on merkkijono, tai Fn::Join jos region on token.
      const raw = transformer.InputTemplate;
      const template: string =
        typeof raw === 'string'
          ? raw
          : raw['Fn::Join'][1]
              .map((part: unknown) => (typeof part === 'string' ? part : 'eu-west-1'))
              .join('');
      const message = JSON.parse(template);

      expect(message.version).toBe('1.0');
      expect(message.source).toBe('custom');
      expect(message.content.textType).toBe('client-markdown');
      expect(message.content.description.length).toBeGreaterThan(0);
      expect(message.content.title.length).toBeLessThanOrEqual(250);

      // stopCode on aina mukana; taskArn yksilöi tehtävän.
      expect(Object.values(transformer.InputPathsMap)).toEqual(
        expect.arrayContaining(['$.detail.stopCode', '$.detail.taskArn'])
      );
    });
  });

  // EventBridge ei escapeta poimittuja arvoja, joten vapaamuotoiset kentät rikkoisivat
  // JSONin jos ne sisältäisivät lainausmerkkejä.
  test('viesteissä ei käytetä vapaamuotoisia kenttiä', () => {
    const rules = buildEcsStackTemplate().findResources('AWS::Events::Rule');

    Object.values(rules)
      .filter((rule) => String(rule.Properties.Name).includes('-task-'))
      .forEach((rule) => {
        const paths = Object.values(
          rule.Properties.Targets[0].InputTransformer.InputPathsMap
        );
        expect(paths).not.toContain('$.detail.stoppedReason');
        expect(paths).not.toContain('$.detail.containers[0].reason');
      });
  });

  test('hälytykset ohjataan Slack-integraation SNS-topiciin', () => {
    const template = buildEcsStackTemplate();
    const rules = template.findResources('AWS::Events::Rule');

    Object.values(rules)
      .filter((rule) => String(rule.Properties.Name).includes('-task-'))
      .forEach((rule) => {
        expect(rule.Properties.Targets).toHaveLength(1);
        expect(rule.Properties.Targets[0].Arn).toBeDefined();
      });
  });
});

describe('EcsStack lokipohjaiset hälytykset', () => {
  // Nämä suodattimet ovat sopimus sovelluksen tulostamien lokirivien kanssa:
  // sanamuodon muuttaminen rikkoo valvonnan hiljaisesti.
  // dbt:n oma "Done. PASS ... ERROR=n" -yhteenvetorivin suodatin on kommentoitu pois
  // ecs-stack.ts:ssä (ks. TODO): tarkoitus on siirtyä exit code -pohjaiseen hälytykseen.
  test('dbt-ajon yhteenvetorivin suodatinta ei enää luoda', () => {
    const filters = buildEcsStackTemplate().findResources('AWS::Logs::MetricFilter');

    const patterns = Object.values(filters).map((f) => f.Properties.FilterPattern);
    expect(patterns).not.toContain('"Done. PASS" -"ERROR=0"');
  });

  test('Lampi-siirtäjän virhesuodatin tunnistaa ERROR-tason lokirivit', () => {
    buildEcsStackTemplate().hasResourceProperties('AWS::Logs::MetricFilter', {
      FilterPattern: '"ERROR" -"WARN" -"INFO"',
      MetricTransformations: Match.arrayWith([
        Match.objectLike({ MetricName: 'LampiSiirtajaFailedError' }),
      ]),
    });
  });

  // CloudWatch ei salli ?-operaattorin ja poissulkevien termien yhdistämistä samaan
  // suodattimeen, joten kirjainkoon variantit ovat omia suodattimiaan samaan metriikkaan.
  test.each(['ERROR', 'Error'])(
    'dbt-kontin %s-suodatin ohjautuu DbtRunnerFailedError-metriikkaan',
    (term) => {
      buildEcsStackTemplate().hasResourceProperties('AWS::Logs::MetricFilter', {
        FilterPattern: `"${term}" -"WARN" -"INFO"`,
        MetricTransformations: Match.arrayWith([
          Match.objectLike({ MetricName: 'DbtRunnerFailedError' }),
        ]),
      });
    }
  );

  test('dbt-kontin virhesuodattimia on kaksi ja molemmat samassa metriikassa', () => {
    const filters = buildEcsStackTemplate().findResources('AWS::Logs::MetricFilter');

    const dbtErrorPatterns = Object.values(filters)
      .filter((f) =>
        f.Properties.MetricTransformations.some(
          (t: { MetricName: string }) => t.MetricName === 'DbtRunnerFailedError'
        )
      )
      .map((f) => f.Properties.FilterPattern);

    expect(dbtErrorPatterns.sort()).toEqual(
      ['"ERROR" -"WARN" -"INFO"', '"Error" -"WARN" -"INFO"'].sort()
    );
  });
});
