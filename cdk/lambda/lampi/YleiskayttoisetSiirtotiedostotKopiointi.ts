/* eslint @typescript-eslint/no-var-requires: "off" */
import * as fs from 'fs';

import * as s3 from '@aws-sdk/client-s3';
import * as sts from '@aws-sdk/client-sts';
import { Handler } from 'aws-cdk-lib/aws-lambda';
import { Context } from 'aws-lambda/handler';
import * as dateFns from 'date-fns-tz';

const { writeFile } = require('node:fs/promises');

const { chain } = require('stream-chain');
const { parser } = require('stream-json');
const { streamArray } = require('stream-json/streamers/StreamArray');
const { batch } = require('stream-json/utils/Batch');
const format = require('string-format');

type Tiedosto = {
  lampiKey: string;
  ovaraKeyTemplate: string;
  batchSize: number;
};

type Tiedostot = {
  [tiedosto: string]: Tiedosto;
};

export const main: Handler = async (event: string, context: Context) => {
  const eraTunniste = context.awsRequestId;

  const tiedostotyyppi = event;

  console.log(
    `Aloitetaan yleiskäyttöisten palveluiden siirtotiedostojen haku: ${tiedostotyyppi}`
  );

  const currentDate = new Date();
  const dateFormatString = 'yyyy-MM-dd_HH.mm.ssxxxx';
  const formattedCurrentDate = dateFns.format(currentDate, dateFormatString, {
    timeZone: 'Europe/Helsinki',
  });

  const tiedostot: Tiedostot = {
    koodisto_koodi: {
      lampiKey: 'fulldump/koodisto/v2/json/koodi.json',
      ovaraKeyTemplate: 'koodisto/koodisto_koodi__{}__{}_{}.json',
      batchSize: 250000,
    },
    koodisto_relaatio: {
      lampiKey: 'fulldump/koodisto/v2/json/relaatio.json',
      ovaraKeyTemplate: 'koodisto/koodisto_relaatio__{}__{}_{}.json',
      batchSize: 250000,
    },
    onr_henkilo: {
      lampiKey: 'fulldump/oppijanumerorekisteri/v2/json/henkilo.json',
      ovaraKeyTemplate: 'onr/onr_henkilo__{}__{}_{}.json',
      batchSize: 500000,
    },
    onr_yhteystieto: {
      lampiKey: 'fulldump/oppijanumerorekisteri/v2/json/yhteystieto.json',
      ovaraKeyTemplate: 'onr/onr_yhteystieto__{}__{}_{}.json',
      batchSize: 100000,
    },
    organisaatio_organisaatio: {
      lampiKey: 'fulldump/organisaatio/v2/json/organisaatio.json',
      ovaraKeyTemplate: 'organisaatio/organisaatio_organisaatio__{}__{}_{}.json',
      batchSize: 50000,
    },
    organisaatio_organisaatiosuhde: {
      lampiKey: 'fulldump/organisaatio/v2/json/organisaatiosuhde.json',
      ovaraKeyTemplate: 'organisaatio/organisaatio_organisaatiosuhde__{}__{}_{}.json',
      batchSize: 5000,
    },
    organisaatio_osoite: {
      lampiKey: 'fulldump/organisaatio/v2/json/osoite.json',
      ovaraKeyTemplate: 'organisaatio/organisaatio_osoite__{}__{}_{}.json',
      batchSize: 50000,
    },
    organisaatio_ryhma: {
      lampiKey: 'fulldump/organisaatio/v3/json/ryhma.json',
      ovaraKeyTemplate: 'organisaatio/organisaatio_ryhma__{}__{}_{}.json',
      batchSize: 20000,
    },
  };

  const siirtotiedostoConfig: any = tiedostot[tiedostotyyppi];
  if (!siirtotiedostoConfig) {
    const message = `Tuntematon tiedostotyyppi: ${tiedostotyyppi}`;
    console.error(message);
    throw new Error(message);
  }

  const lampiBucketName = process.env.lampiBucketName;
  const ovaraBucketName = process.env.ovaraBucketName;

  //const environment = process.env.environment;
  const lampiS3Role = process.env.lampiS3Role;
  const lampiS3ExternalId = process.env.lampiS3ExternalId;

  const stsClient = new sts.STSClient();
  const assumeRoleCommand = new sts.AssumeRoleCommand({
    RoleArn: lampiS3Role,
    RoleSessionName: 'testi-lampi-s3',
    ExternalId: lampiS3ExternalId,
  });
  const lampiS3Credentials = await stsClient.send(assumeRoleCommand);

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

  const getObjectCommand = new s3.GetObjectCommand({
    Bucket: lampiBucketName,
    Key: siirtotiedostoConfig.lampiKey,
  });

  const getObjectResponse: s3.GetObjectCommandOutput =
    await lampiS3Client.send(getObjectCommand);

  if (!getObjectResponse.Body)
    throw new Error(`Tiedoston hakeminen (${siirtotiedostoConfig.lampiKey}) epäonnistui`);

  console.log('S3-tiedosto luettu, käsitellään...');
  const filename = '/tmp/output.json';
  await writeFile(filename, getObjectResponse.Body);
  console.log(`Tiedoston koko: ${fs.statSync(filename).size}`);

  const processDataPromise: Promise<Array<Promise<any>>> = new Promise(function (
    myResolve,
    myReject
  ) {
    try {
      const fileReadStream = fs.createReadStream(filename, {});

      const pipeline = chain([
        fileReadStream,
        parser(),
        streamArray(),
        batch({ batchSize: siirtotiedostoConfig.batchSize }),
      ]);

      pipeline.on('error', (error: any) => {
        console.error(error);
      });

      let summa = 0;
      let batchCount = 1;
      const promises: Array<Promise<any>> = [];
      pipeline.on('data', (data: any) => {
        const ovaraKey = format(
          siirtotiedostoConfig.ovaraKeyTemplate,
          formattedCurrentDate,
          eraTunniste,
          batchCount.toString()
        );

        const entiteetit = data.map((o: any) => o.value);

        console.log(`Tallennetaan tiedosto ${ovaraKey}`);
        const putObjectCommand = new s3.PutObjectCommand({
          Bucket: ovaraBucketName,
          Key: ovaraKey,
          Body: JSON.stringify(entiteetit),
        });
        promises.push(ovaraS3Client.send(putObjectCommand));
        summa = summa + entiteetit.length;
        batchCount++;
      });

      pipeline.on('end', () => {
        console.log(`Käsitellyissä erissä oli yhteensä ${summa} objektia.`);
        console.log('Lopetetaan yleiskäyttöisten palveluiden siirtotiedostojen haku');
        myResolve(promises);
      });
    } catch (err) {
      console.error('Tapahtui yllättävä virhe:', err);
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
      console.error('Promise errored:', error);
    }
  );
  const s3SavePromises: Array<Promise<any>> = await processDataPromise;
  console.log('Odotellaan kaikkien s3-tallennuslupausten valmistumista');
  await Promise.all(s3SavePromises);
  console.log('Kaikki valmista.');
};
