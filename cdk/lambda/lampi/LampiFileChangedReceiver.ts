/* eslint @typescript-eslint/no-var-requires: "off" */
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';
import { DynamoDBDocumentClient, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { APIGatewayProxyEventV2 } from 'aws-lambda';
import { Context } from 'aws-lambda/handler';
import * as dateFns from 'date-fns-tz';

import {
  LampiEvent,
  LampiS3Event,
  lampiKeyExists,
  tiedostotyyppiByLampiKey,
  tiedostot,
  LampiSiirtotiedostoKasiteltyItem,
} from './common';

const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

exports.handler = async (event: APIGatewayProxyEventV2, context: Context) => {
  const awsRegion = process.env.AWS_REGION;
  console.log(`AWS Region: ${awsRegion}`);

  const dateFormatString = 'yyyy-MM-dd HH:mm:ss.SSSxxx';

  const lampiAuthTokenSecretName = process.env.lampiAuthTokenSecretName;

  const parameterCommand = new GetParameterCommand({
    Name: lampiAuthTokenSecretName,
    WithDecryption: true,
  });

  const ssmClient = new SSMClient({ region: awsRegion });
  const ssmResponse = await ssmClient.send(parameterCommand);

  const lampiAuthToken = ssmResponse.Parameter.Value;

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

  const currentDate = new Date();
  const formattedCurrentDate = dateFns.format(currentDate, dateFormatString, {
    timeZone: 'Europe/Helsinki',
  });

  const lampiS3Event: LampiS3Event = lampiEvent.s3;
  const lampiKey = lampiS3Event.object.key;

  if (lampiKeyExists(lampiKey)) {
    const client = new DynamoDBClient({});
    const dynamo = DynamoDBDocumentClient.from(client);

    const tiedostotyyppi = tiedostotyyppiByLampiKey(lampiKey);
    console.log(`Saatu tiedostotyyppi: ${tiedostotyyppi}`);
    const tiedosto = tiedostot[tiedostotyyppi];
    let intervalExceeded = true;
    if (tiedosto.intervalHours) {
      const getCommand = new GetCommand({
        TableName: 'lampiSiirtotiedostoKasitelty',
        Key: {
          tiedostotyyppi: tiedostotyyppi,
        },
      });

      const getResponse = await dynamo.send(getCommand);
      if (getResponse.Item) {
        const lampiSiirtotiedostoKasiteltyItem: LampiSiirtotiedostoKasiteltyItem =
          getResponse.Item as LampiSiirtotiedostoKasiteltyItem;
        const aikaleimaString = lampiSiirtotiedostoKasiteltyItem['aikaleima'];
        const aikaleima: Date = dateFns.toDate(aikaleimaString, {
          timeZone: 'Europe/Helsinki',
        });

        if (!aikaleima) {
          console.error(
            `Tiedostotyypille ${tiedostotyyppi} löytyi Dynamosta virheellinen aikaleima: ${aikaleimaString}`
          );
          throw new Error();
        }

        const compareDate = new Date();
        compareDate.setHours(currentDate.getHours() + tiedosto.intervalHours);
        console.log(
          `Nykyinen aika: ${formattedCurrentDate} | Intervalli (h): ${tiedosto.intervalHours} | Vertailuaika: ${dateFns.format(
            compareDate,
            dateFormatString,
            {
              timeZone: 'Europe/Helsinki',
            }
          )} | Viimeisin käsittelyaika: ${aikaleimaString}`
        );
        if (compareDate.getTime() >= aikaleima.getTime()) {
          console.log(
            `Tiedostotyypin (${tiedostotyyppi}) tiedot löytyivät DynamoDB:stä mutta edellisen tiedoston käsittelystä on liian vähän aikaa. Ei tehdä mitään.`
          );
          intervalExceeded = false;
        } else {
          console.log(
            `Tiedostotyypin (${tiedostotyyppi}) tiedot löytyivät DynamoDB:stä. Edellisestä käsittelystä on kulunut tarpeeksi aikaa. Lähetetään tiedostokäsiteltäväksi`
          );
        }
      } else {
        console.log(
          `Tiedostotyypin (${tiedostotyyppi}) tietoja ei löytynyt DynamoDB:stä. Lähetetään tiedostokäsiteltäväksi.`
        );
      }
    }
    if (intervalExceeded) {
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
      console.log(
        `Tiedosto lähetetty onnistuneesti ladattavaksi (${lampiKey}). Päivitetään ajanhetki Dynamoon.`
      );
      const putCommand = new PutCommand({
        TableName: 'lampiSiirtotiedostoKasitelty',
        Item: {
          tiedostotyyppi: tiedostotyyppi,
          aikaleima: formattedCurrentDate,
        },
      });
      await dynamo.send(putCommand);
    }
  } else {
    console.log(`Tuntematon tiedosto: ${lampiKey}`);
  }

  return {
    statusCode: 200,
  };
};
