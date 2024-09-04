import * as s3 from '@aws-sdk/client-s3';
import { Handler } from 'aws-cdk-lib/aws-lambda';

export const main: Handler = async () => {
  console.log('Testing....');

  const s3client = new s3.S3Client();

  const listObjectsCommand = new s3.ListObjectsCommand({
    Bucket: 'oph-lampi-qa',
    Prefix: '/fulldump/organisaatio/v2/json/',
  });

  const listObjectsOutput = await s3client.send(listObjectsCommand);

  console.log('listObjectsOutput: ' + listObjectsOutput);
};
