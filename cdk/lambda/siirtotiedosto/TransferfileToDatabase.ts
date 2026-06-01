import * as fs from 'fs';
import { Readable } from 'stream';

import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Signer } from '@aws-sdk/rds-signer';
import { Handler } from 'aws-cdk-lib/aws-lambda';
import { S3Event, SQSEvent, SQSRecord } from 'aws-lambda';
import { S3EventRecord } from 'aws-lambda/trigger/s3';
import { parse } from 'date-fns';
import * as pg from 'pg';
import { Sequelize, DataTypes, Model, Dialect } from 'sequelize';
import { parser } from 'stream-json';
import { streamArray } from 'stream-json/streamers/StreamArray';

const client = new S3Client({});

const DEFAULT_DB_POOL_PARAMS = {
  max: 1,
  min: 0,
  idle: 120000,
  acquire: 10000,
};

class Raw extends Model {}

const initRaw = (sequelize: Sequelize, rawTableName: string) => {
  Raw.init(
    {
      data: {
        type: DataTypes.JSON,
      },
      dw_metadata_source_timestamp_at: {
        type: DataTypes.DATE,
      },
      dw_metadata_dbt_copied_at: {
        type: DataTypes.DATE,
      },
      dw_metadata_filename: {
        type: DataTypes.STRING,
      },
      dw_metadata_file_row_number: {
        type: DataTypes.INTEGER,
      },
    },
    {
      schema: 'raw',
      timestamps: false,
      tableName: rawTableName,
      sequelize,
    }
  );
  Raw.removeAttribute('id');
};

const row = (
  json: object,
  exportTime: Date,
  copyTime: Date,
  filename: string,
  counter: number
) => ({
  data: json,
  dw_metadata_source_timestamp_at: exportTime,
  dw_metadata_dbt_copied_at: copyTime,
  dw_metadata_filename: filename,
  dw_metadata_file_row_number: counter,
});

export const main: Handler = async (event: SQSEvent) => {
  const sqsRecords = event.Records;
  if (!sqsRecords || sqsRecords.length === 0) {
    console.log(
      'SQSEventissä ei ole yhtään recordia. Ehkä testi-event? Lopetetaan suorittaminen.'
    );
    return;
  } else if (sqsRecords.length > 1) {
    const message = `SQS-eventissä on enemmän kuin yksi record: ${sqsRecords.length}`;
    console.error(message);
    throw new Error(message);
  }
  const sqsRecord: SQSRecord = sqsRecords[0];

  const s3Event: S3Event = JSON.parse(sqsRecord.body);
  const s3EventRecords: Array<S3EventRecord> = s3Event.Records;
  if (!s3EventRecords || s3EventRecords.length === 0) {
    console.log(
      'S3Eventissä ei ole yhtään recordia. Ehkä testi-event? Lopetetaan suorittaminen.'
    );
    return;
  } else if (s3EventRecords.length > 1) {
    const message = `SQS-eventin S3-recordeissa on enemmän kuin yksi record: ${s3EventRecords.length}`;
    console.error(message);
    throw new Error(message);
  }
  const s3EventRecord: S3EventRecord = s3EventRecords[0];

  const startTime = new Date().getTime();
  const bucket = s3EventRecord.s3.bucket.name;
  const key: string = s3EventRecord.s3.object.key.replace('%2B', '+');

  console.log(`processing key ${key}`);
  const host = process.env.host || '';
  const username = process.env.user || '';
  const database = process.env.database || '';

  const portStr = process.env.port;
  const port = portStr ? Number(portStr) : 5432;

  const batchSizeStr = process.env.batch_size || '';
  const batchSize = batchSizeStr ? Number(batchSizeStr) : 1000;

  const rawTableSplit = key.split('__')[0].split('/');
  const rawTable = rawTableSplit[rawTableSplit.length - 1];
  const exportTimeStr = key.split('__')[1];
  const exportTime = parse(exportTimeStr, 'yyyy-MM-dd_HH.mm.ssX', new Date());
  const source = key.split('/')[0];

  const signer = new Signer({ hostname: host, port, username });
  const token = await signer.getAuthToken();

  const config = {
    ...DEFAULT_DB_POOL_PARAMS,
    host,
    port,
    database,
    username,
    password: token,
    dialectModule: pg,
    dialect: 'postgres' as Dialect,
    dialectOptions: {
      ssl: {
        //enableTrace: true,
        rejectUnauthorized: false,
        cert: fs.readFileSync(__dirname + '/eu-west-1-bundle.pem').toString(),
      },
    },
    logging: false,
  };

  const dbClient = new Sequelize(config);
  try {
    await dbClient.authenticate();
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Tietokantayhteyden muodostaminen epäonnistui' };
  }
  initRaw(dbClient, rawTable);

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  let nbrOfRows = 0;
  try {
    const response = await client.send(command);
    if (!response.Body) {
      throw new Error('S3 response body on tyhjä');
    }
    const now = new Date();
    if (source === 'valintalaskenta') {
      nbrOfRows = await streamJsonArrayToDb(
        response.Body as Readable,
        exportTime,
        now,
        key
      );
    } else {
      const contents: Array<object> = JSON.parse(
        (await response.Body.transformToString()) || '[]'
      );
      nbrOfRows = await saveToDb(contents, batchSize, exportTime, now, key);
    }
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Käsittely epäonnistui' };
  }

  const duration = Math.round((new Date().getTime() - startTime) / 1000);
  console.log(
    `Kirjoitettu kantaan ${nbrOfRows} riviä järjestelmän ${source} tiedostosta ${key}, ajon kesto ${duration} sekuntia`
  );
  return {
    statusCode: 200,
    body: `Lahde: ${source}, rivien lukumaara: ${nbrOfRows}, ajon kesto: ${duration}`,
  };
};

const streamJsonArrayToDb = (
  body: Readable,
  exportTime: Date,
  copyTime: Date,
  filename: string
): Promise<number> => {
  return new Promise((resolve, reject) => {
    let rowCounter = 0;
    let failed = false;
    let pendingWrite: Promise<void> = Promise.resolve();

    const handleError = (err: unknown) => {
      if (!failed) {
        failed = true;
        reject(err);
      }
    };

    const stream = body.pipe(parser()).pipe(streamArray());

    stream.on('data', ({ value }: { value: object }) => {
      if (failed) return;
      stream.pause();
      pendingWrite = pendingWrite
        .then(async () => {
          if (failed) return;
          rowCounter += 1;
          console.log(
            `Kirjoitetaan rivi kerrallaan rivi ${rowCounter} tiedostosta ${filename}`
          );
          await Raw.bulkCreate([row(value, exportTime, copyTime, filename, rowCounter)]);
          stream.resume();
        })
        .catch(handleError);
    });

    stream.on('end', () => {
      pendingWrite
        .then(() => {
          if (!failed) resolve(rowCounter);
        })
        .catch(handleError);
    });

    stream.on('error', handleError);
  });
};

const saveToDb = async (
  data: Array<object>,
  batchSize: number,
  exportTime: Date,
  copyTime: Date,
  filename: string
): Promise<number> => {
  const partitionedData = partition(data, batchSize);
  let rowNumberCounter = 0;
  for (let idx = 0; idx < partitionedData.length; idx++) {
    const batch = partitionedData[idx];
    const rows = batch.map((json) => {
      rowNumberCounter += 1;
      return row(json, exportTime, copyTime, filename, rowNumberCounter);
    });
    await Raw.bulkCreate(rows);
  }
  return rowNumberCounter;
};

const partition = (array: Array<object>, partitionLen: number): Array<Array<object>> => {
  return array.length
    ? [array.splice(0, partitionLen)].concat(partition(array, partitionLen))
    : [];
};
