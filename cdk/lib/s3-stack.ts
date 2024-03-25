import path = require('path');

import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Effect } from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3Props extends GenericStackProps {
  dbClusterResourceId: string;
  dbUser: string;
}

export class S3Stack extends cdk.Stack {
  public readonly deploymentS3Bucket: s3.IBucket;
  constructor(scope: Construct, id: string, props: S3Props) {
    super(scope, id, props);

    const config: Config = props.config;

    const siirtotiedostotBucketName = `${config.environment}-siirtotiedostot`;
    const siirtotiedostotS3Bucket = new s3.Bucket(this, siirtotiedostotBucketName, {
      bucketName: siirtotiedostotBucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: new kms.Key(this, `${siirtotiedostotBucketName}-s3BucketKMSKey`, {
        enableKeyRotation: true,
      }),
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

    const sharedLayer = new lambda.LayerVersion(this, 'shared-layer', {
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/layers')),
      compatibleRuntimes: [lambda.Runtime.PYTHON_3_9],
      layerVersionName: 'shared-layer',
    });

    const fileLoaderLambda = new lambda.Function(this, 'Transferfile loader', {
      functionName: `${config.environment}-transfer-file-loader`,
      runtime: lambda.Runtime.PYTHON_3_9,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/siirtotiedosto')),
      handler: 'lataa.lambda_handler',
      layers: [sharedLayer],
      initialPolicy: [
        new iam.PolicyStatement({
          effect: Effect.ALLOW,
          resources: [
            `arn:aws:rds-db:${props.config.region}:${props.config.accountId}:dbuser:${props.dbClusterResourceId}/${props.dbUser}`,
          ],
          actions: ['rds-db:connect'],
        }),
      ],
    });

    const s3PutEventSource = new lambdaEventSources.S3EventSource(
      siirtotiedostotS3Bucket,
      {
        events: [s3.EventType.OBJECT_CREATED_PUT],
      }
    );
    fileLoaderLambda.addEventSource(s3PutEventSource);
  }
}
