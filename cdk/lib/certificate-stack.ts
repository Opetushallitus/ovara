import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { GenericStackProps } from './config';

export interface CertificateProps extends GenericStackProps {
  publicHostedZone: route53.IHostedZone;
}

export class CertificateStack extends cdk.Stack {
  public readonly ovaraWildcardCertificate;
  constructor(scope: Construct, id: string, props: CertificateProps) {
    super(scope, id, props);

    const config = props.config;

    const ovaraWildcardCertificate = new acm.Certificate(
      this,
      `${config.environment}-${config.publicHostedZone}-wildcard-certificate`,
      {
        domainName: `*.${config.publicHostedZone}`,
        validation: acm.CertificateValidation.fromDns(props.publicHostedZone),
      }
    );

    this.ovaraWildcardCertificate = ovaraWildcardCertificate;
  }
}
