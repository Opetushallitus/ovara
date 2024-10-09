import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export class ExternalRolesStack extends cdk.Stack {
  public readonly githubActionsDeploymentRole: iam.IRole;

  constructor(scope: Construct, id: string, props: GenericStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const githubOidcProvider = new iam.OpenIdConnectProvider(
      this,
      `${config.environment}-OvaraGithubOidcProvider`,
      {
        url: 'https://token.actions.githubusercontent.com',
        thumbprints: ['6938fd4d98bab03faadb97b34396831e3780aea1'],
        clientIds: ['sts.amazonaws.com'],
      }
    );

    this.githubActionsDeploymentRole = new iam.Role(
      this,
      `${config.environment}-OvaraGithubActionsUser`,
      {
        assumedBy: new iam.WebIdentityPrincipal(
          githubOidcProvider.openIdConnectProviderArn,
          {
            StringLike: {
              'token.actions.githubusercontent.com:sub': 'repo:Opetushallitus/ovara:*',
              'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com',
            },
          }
        ),
        roleName: `ovara-${config.environment}-github-actions-deployment-role`,
      }
    );

    cdkNag.NagSuppressions.addStackSuppressions(this, []);
  }
}
