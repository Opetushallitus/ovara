import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3Props extends GenericStackProps {}

export class S3Stack extends cdk.Stack {
  public readonly deploymentS3Bucket: s3.IBucket;
  constructor(scope: Construct, id: string, props: S3Props) {
    super(scope, id, props);

    const config: Config = props.config;

    const siirtotiedostotBucketName = `${config.environment}-siirtotiedostot`;
    const siirtotiedostotKmsKey = new kms.Key(
      this,
      `${siirtotiedostotBucketName}-s3BucketKMSKey`,
      {
        alias: `${siirtotiedostotBucketName}-s3-bucket-kms-key`,
        enableKeyRotation: true,
      }
    );
    const siirtotiedostotS3Bucket = new s3.Bucket(this, siirtotiedostotBucketName, {
      bucketName: siirtotiedostotBucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: siirtotiedostotKmsKey,
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${siirtotiedostotBucketName}-server-access-logs`
      ),
    });

    const s3CrossAccountRole = new iam.Role(
      this,
      `${config.environment}-OpintopolkuS3CrossAccountRole`,
      {
        assumedBy: new iam.ArnPrincipal(
          `arn:aws:iam::${config.opintopolkuAccountId}:root`
        ),
        roleName: `${config.environment}-opintopolku-s3-cross-account-role`,
      }
    );

    const assumeStatement = new iam.PolicyStatement();
    assumeStatement.addResources(siirtotiedostotS3Bucket.bucketArn);
    s3CrossAccountRole.addToPrincipalPolicy(assumeStatement);

    const bucketResourceStatement = new iam.PolicyStatement();
    bucketResourceStatement.addResources(siirtotiedostotS3Bucket.bucketArn);
    bucketResourceStatement.addActions('s3:*Bucket*');
    s3CrossAccountRole.addToPolicy(bucketResourceStatement);

    const objectResourceStatement = new iam.PolicyStatement();
    objectResourceStatement.addResources(`${siirtotiedostotS3Bucket.bucketArn}/*`);
    objectResourceStatement.addActions('s3:*Object*');
    s3CrossAccountRole.addToPolicy(objectResourceStatement);

    const kmsAssumeStatement = new iam.PolicyStatement();
    kmsAssumeStatement.addResources(siirtotiedostotKmsKey.keyArn);
    s3CrossAccountRole.addToPrincipalPolicy(kmsAssumeStatement);

    const kmsResourceStatement = new iam.PolicyStatement();
    kmsResourceStatement.addResources(siirtotiedostotKmsKey.keyArn);
    kmsResourceStatement.addActions(
      'kms:Encrypt',
      'kms:Decrypt',
      'kms:ReEncrypt*',
      'kms:GenerateDataKey*',
      'kms:DescribeKey'
    );
    s3CrossAccountRole.addToPolicy(kmsResourceStatement);

    siirtotiedostotS3Bucket.grantReadWrite(new iam.AccountRootPrincipal());

    const deploymentS3BucketName = `${config.environment}-deployment`;
    this.deploymentS3Bucket = new s3.Bucket(this, deploymentS3BucketName, {
      bucketName: deploymentS3BucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: new kms.Key(this, `${deploymentS3BucketName}-s3BucketKMSKey`, {
        enableKeyRotation: true,
      }),
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${deploymentS3BucketName}-server-access-logs`
      ),
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Account assuming the role delegates only needed access rights',
      },
    ]);
  }
}
