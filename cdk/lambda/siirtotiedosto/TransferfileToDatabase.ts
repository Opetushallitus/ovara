import * as fs from 'fs';

import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Signer } from '@aws-sdk/rds-signer';
import { Handler } from 'aws-cdk-lib/aws-lambda';
import { S3Event } from 'aws-lambda';
import { parse } from 'date-fns';
import * as pg from 'pg';
import { Sequelize, DataTypes, Model } from 'sequelize';

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

export const main: Handler = async (event: S3Event) => {
  const startTime = new Date().getTime();
  const bucket = event.Records[0].s3.bucket.name;
  const key: string = event.Records[0].s3.object.key.replace('%2B', '+');

  console.log(`processing key ${key}`);
  const host = process.env.host || '';
  const username = process.env.user || '';
  const database = process.env.database || '';

  const portStr = process.env.port;
  const port = portStr ? Number(portStr) : 5432;

  const batchSizeStr = process.env.batch_size || '';
  const batchSize = batchSizeStr ? Number(batchSizeStr) : 100;

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
    dialect: 'postgres',
    dialectOptions: {
      ssl: {
        //enableTrace: true,
        rejectUnauthorized: false,
        cert: fs.readFileSync(__dirname + '/eu-west-1-bundle.pem').toString(),
      },
    },
    logging: false,
  };

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  let partitionedContents = new Array<Array<object>>();
  try {
    const response = await client.send(command);
    partitionedContents = partition(
      JSON.parse((await response.Body?.transformToString()) || ''),
      batchSize
    );
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Siirtotiedoston luku epaonnistui' };
  }

  let nbrOfRows = 0;
  try {
    nbrOfRows = await saveToDb(
      config,
      rawTable,
      partitionedContents,
      exportTime,
      key,
      source,
      batchSize
    );
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Tietokantaan kirjoittaminen epaonnistui' };
  }

  const duration = Math.round((new Date().getTime() - startTime) / 1000);
  console.log(
    `Kirjoitettu kantaan ${nbrOfRows} riviä tiedostosta ${key}, ajon kesto ${duration} sekuntia`
  );
  return {
    statusCode: 200,
    body: `Lahde: ${source}, rivien lukumaara: ${nbrOfRows}, ajon kesto: ${duration}`,
  };
};

const saveToDb = async (
  config: object,
  rawTableName: string,
  partitionedData: Array<Array<object>>,
  exportTime: Date,
  filename: string,
  sourceSystem: string,
  batchSize: number
) => {
  const dbClient = new Sequelize(config);
  await dbClient.authenticate();

  initRaw(dbClient, rawTableName);

  const now = new Date();
  let rowNumberCounter = 0;
  for (let idx = 0; idx < partitionedData.length; idx++) {
    const batch = partitionedData[idx];
    const rows = batch.map((json) => {
      rowNumberCounter += 1;
      return row(json, exportTime, now, filename, rowNumberCounter);
    });
    await Raw.bulkCreate(rows);
    console.log(
      `Lisätty tietokantaan ${batch.length} riviä järjestelmästä ${sourceSystem}`
    );
  }
  return rowNumberCounter;
};

const partition = (array: Array<object>, partitionLen: number): Array<Array<object>> => {
  return array.length
    ? [array.splice(0, partitionLen)].concat(partition(array, partitionLen))
    : [];
};
