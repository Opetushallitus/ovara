import { readFileSync } from 'fs';

import * as cdk from 'aws-cdk-lib';

export interface OpiskelijavalinnanRaportointiStackProps extends cdk.StackProps {
  config: Config;
}

export interface Config {
  environment: string;
  publicHostedZone: string;
}

export const getOpiskelijavalinnanRaportointiStackProps = (
  environment: string
): OpiskelijavalinnanRaportointiStackProps => {
  const filename: string = `config/${environment}.json`;
  const fileContent: string = readFileSync(filename, 'utf8');
  const config: Config = JSON.parse(fileContent);
  return { config: config };
};
