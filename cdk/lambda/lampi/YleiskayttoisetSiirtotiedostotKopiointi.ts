import * as s3 from '@aws-sdk/client-s3';
import * as sts from '@aws-sdk/client-sts';
import { Handler } from 'aws-cdk-lib/aws-lambda';

export const main: Handler = async () => {
  console.log('Testing....');

  const environment = process.env.environment;
  const lampiS3Role = process.env.lampiS3Role;
  const lampiS3ExternalId = process.env.lampiS3ExternalId;

  const stsClient = new sts.STSClient();
  const assumeRoleCommand = new sts.AssumeRoleCommand({
    RoleArn: lampiS3Role,
    RoleSessionName: 'testi-lampi-s3',
    ExternalId: lampiS3ExternalId,
  });
  const lampiS3Credentials = await stsClient.send(assumeRoleCommand);
  console.log('lampiS3Credentials: ' + JSON.stringify(lampiS3Credentials, null, 4));

  const lampiAccessKeyId = lampiS3Credentials?.Credentials?.AccessKeyId || '';
  const lampiSecretAccessKey = lampiS3Credentials?.Credentials?.SecretAccessKey || '';
  const lampiSessionToken = lampiS3Credentials?.Credentials?.SessionToken || '';

  const lampiS3Client = new s3.S3Client({
    credentials: {
      accessKeyId: lampiAccessKeyId,
      secretAccessKey: lampiSecretAccessKey,
      sessionToken: lampiSessionToken,
    },
  });

  const getObjectCommand = new s3.GetObjectCommand({
    Bucket: 'oph-lampi-qa',
    Key: '/fulldump/organisaatio/v3/json/ryhma.json',
  });

  const ryhmat = await lampiS3Client.send(getObjectCommand);
  console.log('ryhmat: ' + ryhmat);
};
