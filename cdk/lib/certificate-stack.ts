import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { GenericStackProps } from './config';

export interface CertificateStackProps extends GenericStackProps {}

export class CertificateStack extends cdk.Stack {
  public readonly ovaraWildcardCertificate;
  constructor(scope: Construct, id: string, props: CertificateStackProps) {
    super(scope, id, props);

    const config = props.config;

    const ovaraPublicHostedZone = route53.PublicHostedZone.fromLookup(
      this,
      `${config.environment}-OvaraHostedZone`,
      {
        domainName: `${config.publicHostedZone}`,
      }
    );

    const ovaraWildcardCertificate = new acm.Certificate(
      this,
      `${config.environment}-${config.publicHostedZone}-wildcard-certificate`,
      {
        domainName: `*.${config.publicHostedZone}`,
        validation: acm.CertificateValidation.fromDns(ovaraPublicHostedZone),
      }
    );

    this.ovaraWildcardCertificate = ovaraWildcardCertificate;
  }
}
