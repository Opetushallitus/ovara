import * as fs from 'fs';

import * as cdk from 'aws-cdk-lib';
import * as appscaling from 'aws-cdk-lib/aws-applicationautoscaling';

export interface GenericStackProps extends cdk.StackProps {
  config: Config;
}

export interface Config {
  aurora: {
    backup: {
      deleteAfterDays: number;
    };
    deletionProtection: boolean;
    enablePerformanceInsights: boolean;
    iopsStorage: boolean;
    maxCapacity: number;
    minCapacity: number;
    scaleReaderWithWriter: boolean;
  };
  environment: string;
  lampiFileHandlerActive: string;
  dbtProcessingEnabled: string;
  dbtCron: appscaling.CronOptions;
  profile: string;
  publicHostedZone: string;
  siirtotiedostot: {
    lampiBucketName: string;
    ovaraBucketName: string;
  };
  vpc: {
    maxAzs: number;
    netGateways: number;
  };
}

export const getGenericStackProps = (environment: string): GenericStackProps => {
  const filename: string = `config/${environment}.json`;
  const fileContent: string = fs.readFileSync(filename, 'utf8');
  const config: Config = JSON.parse(fileContent);
  return {
    config: config,
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION,
    },
  };
};
