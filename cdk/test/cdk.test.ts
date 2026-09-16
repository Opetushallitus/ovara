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
  test('dbt-ajon virhesuodatin tunnistaa epäonnistuneen ajon yhteenvetorivin', () => {
    buildEcsStackTemplate().hasResourceProperties('AWS::Logs::MetricFilter', {
      FilterPattern: '"Done. PASS" -"ERROR=0"',
      MetricTransformations: Match.arrayWith([
        Match.objectLike({ MetricName: 'DbtRunnerFailedError' }),
      ]),
    });
  });

  test('Lampi-siirtäjän virhesuodatin tunnistaa ERROR-tason lokirivit', () => {
    buildEcsStackTemplate().hasResourceProperties('AWS::Logs::MetricFilter', {
      FilterPattern: '"ERROR" -"WARN" -"INFO"',
      MetricTransformations: Match.arrayWith([
        Match.objectLike({ MetricName: 'LampiSiirtajaFailedError' }),
      ]),
    });
  });
});
