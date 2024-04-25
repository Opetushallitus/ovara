import path = require('path');

import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudFront from 'aws-cdk-lib/aws-cloudfront';
import { S3Origin } from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import { ARecord, IHostedZone, RecordTarget } from 'aws-cdk-lib/aws-route53';
import { CloudFrontTarget } from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3Props extends GenericStackProps {
  siirtotiedostoLambda: lambda.IFunction;
  ovaraWildcardCertificate: acm.ICertificate;
  zone: IHostedZone;
}

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

    const siirtotiedostoS3Bucket = new s3.Bucket(this, siirtotiedostotBucketName, {
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
      `${config.environment}-S3CrossAccountRole`,
      {
        assumedBy: new iam.CompositePrincipal(
          new iam.ArnPrincipal(`arn:aws:iam::${config.accountId}:root`),
          new iam.ArnPrincipal(`arn:aws:iam::${config.opintopolkuAccountId}:root`)
        ),
        roleName: 'opintopolku-s3-cross-account-role',
      }
    );

    const bucketResourceStatement = new iam.PolicyStatement();
    bucketResourceStatement.addResources(siirtotiedostoS3Bucket.bucketArn);
    bucketResourceStatement.addActions('s3:ListBucket', 's3:ListBucketVersions');
    s3CrossAccountRole.addToPolicy(bucketResourceStatement);

    const objectResourceStatement = new iam.PolicyStatement();
    objectResourceStatement.addResources(`${siirtotiedostoS3Bucket.bucketArn}/*`);
    objectResourceStatement.addActions(
      's3:GetObject',
      's3:PutObject',
      's3:GetObjectAttributes',
      's3:ListMultipartUploadParts',
      's3:AbortMultipartUpload',
      's3:PutObjectTagging'
    );
    s3CrossAccountRole.addToPolicy(objectResourceStatement);

    const kmsResourceStatement = new iam.PolicyStatement();
    kmsResourceStatement.addResources(siirtotiedostotKmsKey.keyArn);
    kmsResourceStatement.addActions(
      'kms:Encrypt',
      'kms:Decrypt',
      'kms:GenerateDataKey',
      'kms:DescribeKey'
    );
    s3CrossAccountRole.addToPolicy(kmsResourceStatement);

    const lambdaExecutionRole = iam.Role.fromRoleArn(
      this,
      'LambdaExecutionRole',
      props.siirtotiedostoLambda.role!.roleArn
    );
    lambdaExecutionRole.addToPrincipalPolicy(objectResourceStatement);
    lambdaExecutionRole.addToPrincipalPolicy(kmsResourceStatement);

    siirtotiedostoS3Bucket.grantReadWrite(new iam.AccountRootPrincipal());

    const s3PutEventSource = new lambdaEventSources.S3EventSource(
      siirtotiedostoS3Bucket,
      {
        events: [
          s3.EventType.OBJECT_CREATED_PUT,
          s3.EventType.OBJECT_CREATED_COMPLETE_MULTIPART_UPLOAD,
        ],
      }
    );
    props.siirtotiedostoLambda.addEventSource(s3PutEventSource);

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

    const dokumentaatioBucket = new s3.Bucket(
      this,
      `${config.environment}-dokumentaatio`,
      {
        enforceSSL: true,
        bucketName: `${config.environment}-ovara-dokumentaatio`,
      }
    );

    const dokumentaatioCloudFrontToS3 = new cloudFront.Distribution(
      this,
      `${config.environment}-dokumentaatio-cloudfront-to-s3`,
      {
        defaultRootObject: 'index.html',
        defaultBehavior: {
          origin: new S3Origin(dokumentaatioBucket),
        },
        domainNames: [`dokumentaatio.${config.publicHostedZone}`],
        minimumProtocolVersion: cloudFront.SecurityPolicyProtocol.TLS_V1_2_2021,
        certificate: props.ovaraWildcardCertificate,
      }
    );

    new ARecord(this, `${config.environment}-dokumentaatio-arecord`, {
      zone: props.zone,
      recordName: 'dokumentaatio',
      target: RecordTarget.fromAlias(new CloudFrontTarget(dokumentaatioCloudFrontToS3)),
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-S1',
        reason: 'Not interested in access logs',
      },
      {
        id: 'AwsSolutions-CFR3',
        reason: 'Not interested in access logs',
      },
    ]);
  }
}
