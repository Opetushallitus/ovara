import { Context } from 'aws-lambda/handler';

type LampiS3Event = {
  s3SchemaVersion: string;
  configurationId: string;
  bucket: {
    name: string;
    ownerIdentity: {
      principalId: string;
    };
    arn: string;
  };
  object: {
    key: string;
    size: number;
    eTag: string;
    versionId?: string | undefined;
    sequencer: string;
  };
};

type LampiEvent = {
  token: string;
  s3: LampiS3Event;
};

exports.handler = async (event: any, context: Context) => {
  console.log(JSON.stringify(event, null, 4));
  return {
    statusCode: 200,
  };
};
