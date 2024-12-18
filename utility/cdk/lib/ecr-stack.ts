import * as cdk from 'aws-cdk-lib';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';

export class EcrStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const dbtRunnerRepositoryName = 'ovara-dbt-runner';
    const dbtRunnerRepository = new ecr.Repository(this, dbtRunnerRepositoryName, {
      repositoryName: dbtRunnerRepositoryName,
      imageScanOnPush: true,
    });

    const lampiSiirtajaRepositoryName = 'ovara-lampi-siirtaja';
    const lampiSiirtajaRepository = new ecr.Repository(this, lampiSiirtajaRepositoryName, {
      repositoryName: lampiSiirtajaRepositoryName,
      imageScanOnPush: true,
    });

    const githubOidcProvider = new iam.OpenIdConnectProvider(this, `OvaraUtilityGithubOidcProvider`, {
      url: 'https://token.actions.githubusercontent.com',
      thumbprints: ['6938fd4d98bab03faadb97b34396831e3780aea1'],
      clientIds: ['sts.amazonaws.com'],
    });

    const githubActionsDeploymentRole = new iam.Role(this, `OvaraUtilityGithubActionsUser`, {
      assumedBy: new iam.WebIdentityPrincipal(
        githubOidcProvider.openIdConnectProviderArn,
        {
          StringLike: {
            'token.actions.githubusercontent.com:sub': 'repo:Opetushallitus/ovara:*',
            'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
          },
        },
      ),
      roleName: 'ovara-utility-github-actions-deployment-role',
    });

    dbtRunnerRepository.grantPush(githubActionsDeploymentRole);
    lampiSiirtajaRepository.grantPush(githubActionsDeploymentRole);

    const ovaraTestiAccountId = ssm.StringParameter.valueForStringParameter(
      this,
      '/utility/ovara-testi-account-id'
    );

    const ovaraTuotantoAccountId = ssm.StringParameter.valueForStringParameter(
      this,
      '/utility/ovara-tuotanto-account-id'
    );

    dbtRunnerRepository.addToResourcePolicy(new PolicyStatement({
      actions: [
        'ecr:GetAuthorizationToken',
        'ecr:BatchCheckLayerAvailability',
        'ecr:GetDownloadUrlForLayer',
        'ecr:BatchGetImage',
      ],
      effect: iam.Effect.ALLOW,
      principals: [
        new iam.ArnPrincipal(`arn:aws:iam::${ovaraTestiAccountId}:root`),
        new iam.ArnPrincipal(`arn:aws:iam::${ovaraTuotantoAccountId}:root`),
      ]
    }));

    lampiSiirtajaRepository.addToResourcePolicy(new PolicyStatement({
      actions: [
        'ecr:GetAuthorizationToken',
        'ecr:BatchCheckLayerAvailability',
        'ecr:GetDownloadUrlForLayer',
        'ecr:BatchGetImage',
      ],
      effect: iam.Effect.ALLOW,
      principals: [
        new iam.ArnPrincipal(`arn:aws:iam::${ovaraTestiAccountId}:root`),
        new iam.ArnPrincipal(`arn:aws:iam::${ovaraTuotantoAccountId}:root`),
      ]
    }));

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: 'In this case it is ok.' },
    ]);

  }
}
