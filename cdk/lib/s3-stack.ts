import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3Props extends GenericStackProps {}

export class S3Stack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: S3Props) {
    super(scope, id, props);

    const config: Config = props.config;

    const siirtotiedostotBucketName = `${config.environment}-siirtotiedostot`;
    const siirtotiedostotS3Bucket = new s3.Bucket(this, siirtotiedostotBucketName, {
      bucketName: siirtotiedostotBucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: new kms.Key(this, `${siirtotiedostotBucketName}-s3BucketKMSKey`),
    });

    siirtotiedostotS3Bucket.grantRead(new iam.AccountRootPrincipal());
  }
}
