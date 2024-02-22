import * as cdk from 'aws-cdk-lib';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

<<<<<<< ours
export class VpcStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
=======
import { Config, OpiskelijavalinnanRaportointiStackProps } from './config';

export class NetworkStack extends cdk.Stack {
  constructor(
    scope: Construct,
    id: string,
    props: OpiskelijavalinnanRaportointiStackProps
  ) {
    super(scope, id, props);

    const config: Config = props.config;

    const myHostedZone = new route53.HostedZone(
      this,
      'OpiskelijavalinnanRaportointiHostedZone',
      {
        zoneName: config.publicHostedZone,
      }
    );
>>>>>>> theirs
  }
}
