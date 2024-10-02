/* eslint @typescript-eslint/no-var-requires: "off" */
import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';
import { APIGatewayProxyEventV2 } from 'aws-lambda';
import { Context } from 'aws-lambda/handler';

import { LampiEvent, LampiS3Event, lampiKeyExists } from './common';

const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

exports.handler = async (event: APIGatewayProxyEventV2, context: Context) => {
  const awsRegion = process.env.AWS_REGION;
  console.log(`AWS Region: ${awsRegion}`);

  const lampiAuthTokenSecretName = process.env.lampiAuthTokenSecretName;
  console.log(`lampiAuthTokenSecretName: ${lampiAuthTokenSecretName}`);

  const parameterCommand = new GetParameterCommand({
    Name: lampiAuthTokenSecretName,
    WithDecryption: true,
  });

  const ssmClient = new SSMClient({ region: awsRegion });
  const ssmResponse = await ssmClient.send(parameterCommand);

  const lampiAuthToken = ssmResponse.Parameter.Value;
  console.log(`lampiAuthToken: ${lampiAuthToken}`);

  console.log(JSON.stringify(event, null, 4));

  if (!event?.body) {
    console.error('Viestissä ei ollut bodya tai viesti oli tyhjä');
    return {
      statusCode: 500,
    };
  }

  const lampiEvent: LampiEvent = JSON.parse(event.body);

  if (lampiEvent.token !== lampiAuthToken) {
    console.error('Autentikaatio epäonnistui!');
    return {
      statusCode: 401,
    };
  }

  const lampiS3Event: LampiS3Event = lampiEvent.s3;
  const lampiKey = lampiS3Event.object.key;

  if (lampiKeyExists(lampiKey)) {
    console.log(
      `Uusi tunnistettu tiedosto saapunut Lampeen (${lampiKey}). Lähetetään tiedosto ladattavaksi.`
    );
    const sqsClient = new SQSClient();
    const sendMessageCommand: SendMessageCommand = new SendMessageCommand({
      DelaySeconds: 2,
      MessageBody: JSON.stringify(lampiS3Event),
      QueueUrl: process.env.lampiSiirtotiedostoQueueUrl,
    });

    await sqsClient.send(sendMessageCommand);
    console.log(`Tiedosto lähetetty onnistuneesti ladattavaksi (${lampiKey}).`);
  } else {
    console.log(`Tuntematon tiedosto: ${lampiKey}`);
  }

  return {
    statusCode: 200,
  };
};
