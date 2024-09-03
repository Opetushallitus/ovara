import * as fs from 'fs';

import * as cdk from 'aws-cdk-lib';

export interface GenericStackProps extends cdk.StackProps {
  config: Config;
}

export interface Config {
  aurora: {
    backup: {
      deleteAfterDays: number;
    };
  };
  environment: string;
  profile: string;
  publicHostedZone: string;
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
