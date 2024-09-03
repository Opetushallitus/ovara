import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudFront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3StackProps extends GenericStackProps {
  ovaraWildcardCertificate: acm.ICertificate;
  zone: route53.IHostedZone;
}

export class S3Stack extends cdk.Stack {
  public readonly deploymentS3Bucket: s3.IBucket;
  public readonly siirtotiedostoPutEventSource: cdk.aws_lambda_event_sources.S3EventSource;
  constructor(scope: Construct, id: string, props: S3StackProps) {
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

    const opintopolkuAccountId = ssm.StringParameter.valueForStringParameter(
      this,
      '/testi/opintopolku-account-id'
    );

    const s3CrossAccountRole = new iam.Role(
      this,
      `${config.environment}-S3CrossAccountRole`,
      {
        assumedBy: new iam.CompositePrincipal(
          new iam.AccountRootPrincipal(),
          new iam.ArnPrincipal(`arn:aws:iam::${opintopolkuAccountId}:root`)
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
    new cdk.CfnOutput(this, 'SiirtotiedostoBucketArn', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-bucket-arn`,
      description: 'Siirtotiedosto bucket arn',
      value: `${siirtotiedostoS3Bucket.bucketArn}`,
    });

    const kmsResourceStatement = new iam.PolicyStatement();
    kmsResourceStatement.addResources(siirtotiedostotKmsKey.keyArn);
    kmsResourceStatement.addActions(
      'kms:Encrypt',
      'kms:Decrypt',
      'kms:GenerateDataKey',
      'kms:DescribeKey'
    );
    s3CrossAccountRole.addToPolicy(kmsResourceStatement);
    new cdk.CfnOutput(this, 'SiirtotiedostoKeyArn', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-key-arn`,
      description: 'Siirtotiedosto key arn',
      value: siirtotiedostotKmsKey.keyArn,
    });

    siirtotiedostoS3Bucket.grantReadWrite(new iam.AccountRootPrincipal());

    this.siirtotiedostoPutEventSource = new lambdaEventSources.S3EventSource(
      siirtotiedostoS3Bucket,
      {
        events: [
          s3.EventType.OBJECT_CREATED_PUT,
          s3.EventType.OBJECT_CREATED_COMPLETE_MULTIPART_UPLOAD,
        ],
      }
    );

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
          origin: new cloudfrontOrigins.S3Origin(dokumentaatioBucket),
        },
        domainNames: [`dokumentaatio.${config.publicHostedZone}`],
        minimumProtocolVersion: cloudFront.SecurityPolicyProtocol.TLS_V1_2_2021,
        certificate: props.ovaraWildcardCertificate,
      }
    );

    new route53.ARecord(this, `${config.environment}-dokumentaatio-arecord`, {
      zone: props.zone,
      recordName: 'dokumentaatio',
      target: route53.RecordTarget.fromAlias(
        new route53Targets.CloudFrontTarget(dokumentaatioCloudFrontToS3)
      ),
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Wildcard used only for bucket contents',
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
