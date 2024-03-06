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

    //const opintopolkuAccountPrincipal = new iam.AccountPrincipal(config.opintopolkuAccountId);
    /*
    siirtotiedostotS3Bucket.addToResourcePolicy(new iam.PolicyStatement({
      actions: ['s3:*'],
      resources: [siirtotiedostotS3Bucket.arnForObjects('*')],
      principals: [opintopolkuAccountPrincipal]
    }));
     */

    const s3CrossAccountRole = new iam.Role(this, 'OpintopolkuS3CrossAcountRole', {
      assumedBy: new iam.ArnPrincipal(`arn:aws:iam::${config.opintopolkuAccountId}:root`),
      roleName: 'opintopolku-s3-cross-account-role',
    });

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
  }
}
