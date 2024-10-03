import * as cdk from 'aws-cdk-lib';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import { Construct } from 'constructs';

export class EcrStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const dbtRunnerRepositoryName = 'ovara-dbt-runner';
    const dbtRunnerRepository = new ecr.Repository(this, dbtRunnerRepositoryName, {
      repositoryName: dbtRunnerRepositoryName,
      imageScanOnPush: true,
    });
  }
}
