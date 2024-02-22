import { readFileSync } from 'fs';

import * as cdk from 'aws-cdk-lib';

export interface OpiskelijavalinnanRaportointiStackProps extends cdk.StackProps {
  config: Config;
}

export interface Config {
  environment: string;
  publicHostedZone: string;
}

export const getConfig = (
  environment: string
): OpiskelijavalinnanRaportointiStackProps => {
  const filename: string =
    environment === 'tuotanto' ? '../config/tuotanto.json' : 'config/testi.json';
  const fileContent: string = readFileSync(filename, 'utf8');
  const config: Config = JSON.parse(fileContent);
  return { config: config };
};
