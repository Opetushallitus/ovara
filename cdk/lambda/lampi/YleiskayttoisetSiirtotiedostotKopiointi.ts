/* eslint @typescript-eslint/no-var-requires: "off" */
import * as fs from 'fs';

import * as s3 from '@aws-sdk/client-s3';
import * as sts from '@aws-sdk/client-sts';
import { Signer } from '@aws-sdk/rds-signer';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { SQSEvent } from 'aws-lambda';
import { Context } from 'aws-lambda/handler';
import * as dateFns from 'date-fns-tz';
import * as pg from 'pg';
import { Options, Sequelize } from 'sequelize';

import * as common from './common';
import { LampiS3Event } from './common';

const { writeFile } = require('node:fs/promises');

const { chain } = require('stream-chain');
const { parser } = require('stream-json');
const { streamArray } = require('stream-json/streamers/StreamArray');
const { batch } = require('stream-json/utils/Batch');
const format = require('string-format');

const DEFAULT_DB_POOL_PARAMS = {
  max: 1,
  min: 0,
  idle: 120000,
  acquire: 10000,
};

export const main: lambda.Handler = async (
  event: string | SQSEvent,
  context: Context
) => {
  const eraTunniste = context.awsRequestId;

  let tiedostotyyppi;
  let sqsRecord;
  if (typeof event === 'string') {
    tiedostotyyppi = event;
  } else {
    if (event.Records.length > 1) {
      const message = `SQS-eventissä on enemmän kuin yksi record: ${event.Records.length}`;
      console.error(message);
      throw new Error(message);
    }
    console.log(event);
    console.log(JSON.stringify(event, null, 4));
    sqsRecord = event.Records[0];
    const lampiS3Event: LampiS3Event = JSON.parse(sqsRecord.body);
    tiedostotyyppi = common.tiedostotyyppiByLampiKey(lampiS3Event.object.key);
  }

  console.log(
    `Aloitetaan yleiskäyttöisten palveluiden siirtotiedostojen haku: ${tiedostotyyppi}`
  );

  const currentDate = new Date();
  const dateFormatString = 'yyyy-MM-dd_HH.mm.ssxxxx';
  const formattedCurrentDate = dateFns.format(currentDate, dateFormatString, {
    timeZone: 'Europe/Helsinki',
  });

  const tiedostot: common.Tiedostot = common.tiedostot;

  const siirtotiedostoConfig: any = tiedostot[tiedostotyyppi];
  if (!siirtotiedostoConfig) {
    const message = `Tuntematon tiedostotyyppi: ${tiedostotyyppi}`;
    console.error(message);
    throw new Error(message);
  }

  const host = process.env.host || '';
  const username = process.env.user || '';
  const database = process.env.database || '';

  const portStr = process.env.port;
  const port = portStr ? Number(portStr) : 5432;

  const signer = new Signer({ hostname: host, port, username });
  const token = await signer.getAuthToken();

  const databaseConfig: Options = {
    ...DEFAULT_DB_POOL_PARAMS,
    host,
    port,
    database,
    username,
    password: token,
    dialectModule: pg,
    dialect: 'postgres',
    dialectOptions: {
      ssl: {
        enableTrace: false,
        rejectUnauthorized: false,
        cert: fs.readFileSync(__dirname + '/eu-west-1-bundle.pem').toString(),
      },
    },
    logging: false,
  };

  const dbClient = new Sequelize(databaseConfig);
  await dbClient.authenticate();

  if (tiedostotyyppi == 'onr_henkilo') {
    console.log('Siivotaan tiedot pois raw.onr_henkilo-taulusta');
    await dbClient.query('truncate table raw.onr_henkilo');
    console.log('Siivottu tiedot pois raw.onr_henkilo-taulusta');
  } else if (tiedostotyyppi == 'koodisto_koodi') {
    console.log('Merkitään että koodisto_koodi on käsittelyssä')
    await dbClient.query("insert into raw.loading (file) values ('koodisto_koodi'))")
    console.log('Siivotaan tiedot pois raw.koodisto_koodi-taulusta');
    await dbClient.query('truncate table raw.koodisto_koodi');
    console.log('Siivottu tiedot pois raw.koodisto_koodi-taulusta');
  } else if (tiedostotyyppi == 'koodisto_relaatio') {
    console.log('Merkitään että koodisto_relaatio on käsittelyssä')
    await dbClient.query("insert into raw.loading (file) values ('koodisto_relaatio')")
    console.log('Siivotaan tiedot pois raw.koodisto_relaatio-taulusta');
    await dbClient.query('truncate table raw.koodisto_relaatio');
    console.log('Siivottu tiedot pois raw.koodisto_relaatio-taulusta');
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

  if (tiedostotyyppi == 'koodisto_koodi') {
    console.log('Merkitään että koodisto_koodi on valmis')
    await dbClient.query("delete from raw.loading where file='koodisto_koodi'")
  } else if (tiedostotyyppi == 'koodisto_relaatio') {
    console.log('Merkitään että koodisto_relaatio on valmis')
    await dbClient.query("delete from raw.loading where file='koodisto_relaatio'")
  }
    console.log('Kaikki valmista.');
};
