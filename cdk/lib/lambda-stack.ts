import path = require('path');

import * as cdk from 'aws-cdk-lib';
import { Duration } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
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

    const executionRole = new iam.Role(this, `${config.environment}-LambdaRole`, {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
    });
    executionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaVPCAccessExecutionRole'
      )
    );

    this.siirtotiedostoLambda = new lambda.Function(this, 'Transferfile loader', {
      functionName: `${config.environment}-transfer-file-loader`,
      runtime: lambda.Runtime.PYTHON_3_12,
      architecture: lambda.Architecture.ARM_64,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../lambda/siirtotiedosto')),
      handler: 'AddDataToDatabase.lambda_handler',
      layers: [sharedLayer],
      vpc: props.vpc,
      securityGroups: [lambdaSecurityGroup],
      role: executionRole,
      environment: {
        host: '',
        database: 'ovara',
        user: 'insert_raw_user',
        port: '5432',
      },
      memorySize: 512,
      timeout: Duration.seconds(300),
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
    ]);
  }
}
