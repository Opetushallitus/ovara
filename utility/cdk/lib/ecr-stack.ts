import * as cdk from 'aws-cdk-lib';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

export class EcrStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const dbtRunnerRepositoryName = 'ovara-dbt-runner';
    const dbtRunnerRepository = new ecr.Repository(this, dbtRunnerRepositoryName, {
      repositoryName: dbtRunnerRepositoryName,
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
            'token.actions.githubusercontent.com:sub': 'repo:Opetushallitus/ovara',
            'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
          },
        },
      ),
      roleName: 'ovara-utility-github-actions-deployment-role',
    });

    dbtRunnerRepository.grantPush(githubActionsDeploymentRole);

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: 'In this case it is ok.' },
    ]);

  }
}
