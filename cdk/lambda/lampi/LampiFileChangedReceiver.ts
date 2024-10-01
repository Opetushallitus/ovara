import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';
import { APIGatewayProxyEventV2 } from 'aws-lambda';
import { Context } from 'aws-lambda/handler';

import { LampiEvent, LampiS3Event, lampiKeyExists } from './common';

exports.handler = async (event: APIGatewayProxyEventV2, context: Context) => {
  console.log(JSON.stringify(event, null, 4));
  if (!event?.body) {
    console.error('Viestissä ei ollut bodya tai viesti oli tyhjä');
    return {
      statusCode: 500,
    };
  }
  const lampiEvent: LampiEvent = JSON.parse(event.body);
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
