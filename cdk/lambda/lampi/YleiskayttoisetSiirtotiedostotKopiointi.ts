import * as fs from 'fs';

import * as s3 from '@aws-sdk/client-s3';
import * as sts from '@aws-sdk/client-sts';
import { Handler } from 'aws-cdk-lib/aws-lambda';
import * as dateFns from 'date-fns-tz';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { writeFile } = require('node:fs/promises');

const { chain } = require('stream-chain');
// eslint-disable-next-line @typescript-eslint/no-var-requires

const { parser } = require('stream-json');
const StreamArray = require('stream-json/streamers/StreamArray');
const { streamArray } = require('stream-json/streamers/StreamArray');
const format = require('string-format');
const { v7: uuidv7 } = require('uuid');

// @ts-expect-error 123
export const main: Handler = async (event, context) => {
  //const eraTunniste = uuidv7();
  const eraTunniste = context.awsRequestId;

  const tiedostotyyppi = event;

  const logInfo = (message: string) => {
    console.log(`${eraTunniste} | ${message}`);
  };
  const logError = (message: string) => {
    console.error(`${eraTunniste} | ${message}`);
  };

  logInfo(
    `Aloitetaan yleiskäyttöisten palveluiden siirtotiedostojen haku: ${tiedostotyyppi}`
  );

  const currentDate = new Date();
  const dateFormatString = 'yyyy-MM-dd_HH:mm:ssxxx';
  const formattedCurrentDate = dateFns.format(currentDate, dateFormatString, {
    timeZone: 'Europe/Helsinki',
  });
  logInfo(formattedCurrentDate);

  const tiedostot = {
    organisaatio_ryhmat: {
      lampiKey: 'fulldump/organisaatio/v3/json/ryhma.json',
      ovaraKeyTemplate: 'organisaatio/organisaatio_ryhma__{}__{}_{}.json',
      batchSize: 5000,
    },
    onr_henkilo: {
      lampiKey: 'fulldump/oppijanumerorekisteri/v2/json/henkilo.json',
      ovaraKeyTemplate: 'onr/onr_henkilo__{}__{}_{}.json',
      batchSize: 1000,
    },
  };

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
  logInfo('lampiS3Credentials: ' + JSON.stringify(lampiS3Credentials, null, 4));

  const lampiAccessKeyId = lampiS3Credentials?.Credentials?.AccessKeyId || '';
  const lampiSecretAccessKey = lampiS3Credentials?.Credentials?.SecretAccessKey || '';
  const lampiSessionToken = lampiS3Credentials?.Credentials?.SessionToken || '';

  const ovaraS3Client = new s3.S3Client();
  const lampiS3Client = new s3.S3Client({
    credentials: {
      accessKeyId: lampiAccessKeyId,
      secretAccessKey: lampiSecretAccessKey,
      sessionToken: lampiSessionToken,
    },
  });

  // @ts-expect-error 123
  const siirtotiedostoConfig = tiedostot[tiedostotyyppi];

  const getObjectCommand = new s3.GetObjectCommand({
    Bucket: 'oph-lampi-qa',
    Key: siirtotiedostoConfig.lampiKey,
  });

  const getObjectResponse: s3.GetObjectCommandOutput =
    await lampiS3Client.send(getObjectCommand);
  //const body: Readable = getObjectResponse.Body as Readable;
  //const tiedostoJson = await consumers.json(body) as [];
  //const body = getObjectResponse.Body;

  console.log('S3-tiedosto luettu, käsitellään...');
  const filename = '/tmp/output.json';
  await writeFile(filename, getObjectResponse.Body);
  logInfo(`Tiedoston koko: ${fs.statSync(filename).size}`);

  const processDataPromise: Promise<Array<Promise<any>>> = new Promise(function (
    myResolve,
    myReject
  ) {
    try {
      const fileReadStream = fs.createReadStream(filename, {});

      logInfo('Valmistellaan pipeline');

      // @ts-ignore
      const objectArray = [];
      const pipeline = chain([
        fileReadStream,
        parser(),
        streamArray(),
        // @ts-ignore
        (data) => {
          const currentLength = objectArray.length;
          if (currentLength % 10000 === 0) {
            console.log('Length', currentLength);
          }
          const value = data.value;
          //logInfo(value);
          objectArray.push(value);
          return data;
        },
      ]);

      logInfo('Pipeline valmisteltu');

      pipeline.on('error', (error: any) => {
        logError(error);
      });

      let counter = 0;
      pipeline.on('data', () => {
        ++counter;
      });

      const promises: Array<Promise<any>> = [];
      pipeline.on('end', () => {
        logInfo(`Tiedostossa on yhteensä ${objectArray.length} objektia.`);

        let i = 1;
        let summa = 0;
        for (
          let processed = 0;
          processed < objectArray.length;
          processed += siirtotiedostoConfig.batchSize
        ) {
          const start = processed + 1;
          const end = Math.min(
            processed + siirtotiedostoConfig.batchSize,
            objectArray.length
          );
          logInfo(`Käsitellään erä numero ${i}: ${start}-${end}`);

          const ovaraKey = format(
            siirtotiedostoConfig.ovaraKeyTemplate,
            formattedCurrentDate,
            eraTunniste,
            i.toString()
          );
          logInfo(ovaraKey);

          // @ts-ignore
          const batch = objectArray.slice(processed, end);
          summa = summa + batch.length;

          logInfo(`Tallennetaan tiedosto ${ovaraKey}`);
          const putObjectCommand = new s3.PutObjectCommand({
            Bucket: 'testi-temp-siirtotiedostot',
            Key: ovaraKey,
            Body: JSON.stringify(batch),
          });
          promises.push(ovaraS3Client.send(putObjectCommand));
          i++;
        }
        logInfo(`Käsitellyissä erissä oli yhteensä ${summa} objektia.`);
        logInfo('Lopetetaan yleiskäyttöisten palveluiden siirtotiedostojen haku');
        myResolve(promises);
      });
    } catch (err) {
      console.log('Tapahtui yllättävä virhe:', err);
      myReject(err);
    }
  });

  processDataPromise.then(
    function (value) {
      console.log(
        'Processing promise finished successfully, promises created: ',
        value.length
      );
    },
    function (error) {
      console.log('Promise errored:', error);
    }
  );
  const s3SavePromises: Array<Promise<any>> = await processDataPromise;
  console.log('Odotellaan kaikkien s3-tallennuslupausten valmistumista');
  await Promise.all(s3SavePromises);
  console.log('Kaikki valmista.');
};
