import path = require('path');

import * as cdk from 'aws-cdk-lib';
import { Duration } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface LambdaProps extends GenericStackProps {
  vpc: ec2.IVpc;
}

export class LambdaStack extends cdk.Stack {
  public readonly siirtotiedostoLambda: lambda.IFunction;
  constructor(scope: Construct, id: string, props: LambdaProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const sharedLayer = new lambda.LayerVersion(this, 'shared-layer', {
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/layers')),
      compatibleRuntimes: [lambda.Runtime.PYTHON_3_12],
      layerVersionName: 'shared-layer',
    });

    const lambdaSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-LambdaSecurityGroup`,
      {
        vpc: props.vpc,
        allowAllOutbound: true,
        description: 'Security group for lambda',
        securityGroupName: `${config.environment}-opiskelijavalinnanraportointi-lambda`,
      }
    );

    const auroraSecurityGroupId = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-aurora-securitygroupid`
    );

    const auroraSecurityGroup = ec2.SecurityGroup.fromSecurityGroupId(
      this,
      'PostgresSecurityGroup',
      auroraSecurityGroupId
    );

    auroraSecurityGroup.addIngressRule(
      lambdaSecurityGroup,
      ec2.Port.tcp(5432),
      'DB sallittu lambdoille'
    );

    const auroraClusterResourceId = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-aurora-cluster-resourceid`
    );

    const dbConnectStatement = new iam.PolicyStatement();
    dbConnectStatement.addResources(
      `arn:aws:rds-db:${props.config.region}:${props.config.accountId}:dbuser:${auroraClusterResourceId}/insert_raw_user`
    );
    dbConnectStatement.addActions('rds-db:connect');
    const dbConnectPolicyDocument = new iam.PolicyDocument();
    dbConnectPolicyDocument.addStatements(dbConnectStatement);

    const executionRole = new iam.Role(this, `${config.environment}-LambdaRole`, {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      inlinePolicies: { dbConnectPolicyDocument },
    });
    executionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaVPCAccessExecutionRole'
      )
    );

    const dbEndpointName = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-database-endpoint`
    );

    this.siirtotiedostoLambda = new NodejsFunction(this, 'Transferfile loader', {
      entry: '../../lambda/siirtotiedosto/TransferfileToDatabase.ts',
      handler: 'main',
      runtime: lambda.Runtime.NODEJS_20_X,
      architecture: lambda.Architecture.ARM_64,
      timeout: Duration.seconds(300),
      memorySize: 512,
      vpc: props.vpc,
      securityGroups: [lambdaSecurityGroup],
      role: executionRole,
      environment: {
        host: dbEndpointName,
        database: 'ovara',
        user: 'insert_raw_user',
        port: '5432',
      },
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
    ]);
  }
}
