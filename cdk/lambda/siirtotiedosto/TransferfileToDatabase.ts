import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { Signer } from '@aws-sdk/rds-signer';
import { Handler } from 'aws-cdk-lib/aws-lambda';
import { parse } from 'date-fns';
import { Client } from 'pg';
import * as pgPromise from 'pg-promise';

const client = new S3Client({});

const DEFAULT_DB_POOL_PARAMS = {
  max: 1,
  min: 0,
  idleTimeoutMillis: 120000,
  connectionTimeoutMillis: 10000,
};

export const main: Handler = async (event, _context) => {
  const startTime = new Date().getTime();
  const bucket = event.Records[0].s3.bucket.name;
  const key: string = event.Records[0].s3.object.key;

  const host = process.env.host || '';
  const user = process.env.user || '';
  const database = process.env.database || '';

  const portStr = process.env.port;
  const port = portStr ? Number(portStr) : 5432;

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  let contents = '';
  try {
    const response = await client.send(command);
    contents = (await response.Body?.transformToString()) || '';
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Siirtotiedoston luku epaonnistui' };
  }
  const contentJson: Array<object> = JSON.parse(contents);
  const filename = key.replace('%2B', '+');
  const rawTable = filename.split('__')[0].split('/')[-1];
  const exportTimeStr = filename.split('__')[1];
  const exportTime = parse(exportTimeStr, 'yyyy-MM-dd_HH:mm:ss xx', new Date());
  const source = filename.split('/')[1];

  const signer = new Signer({ hostname: host, port, username: user });
  const token = await signer.getAuthToken();

  const config = {
    ...DEFAULT_DB_POOL_PARAMS,
    host,
    port,
    database,
    user,
    password: token,
    ssl: {
      rejectUnauthorized: false,
      cert: 'eu-west-1-bundle.pem',
    },
  };
  const dbClient = new Client(config);
  await dbClient.connect();

  try {
    const pgp = pgPromise();
    const db = pgp(dbClient);
    const columns = new pgp.helpers.ColumnSet(
      [
        'data',
        'dw_metadata_source_timestamp_at',
        'dw_metadata_dbt_copied_at',
        'dw_metadata_filename',
        'dw_metadata_file_row_number',
      ],
      { table: `raw.${rawTable}` }
    );

    const now = new Date();
    let rowNumberCounter = 0;
    const partitionedData = partition(contentJson, 2500);
    partitionedData.forEach(async (partition) => {
      const rows = partition.map((json) => ({
        data: json,
        dw_metadata_source_timestamp_at: exportTime,
        dw_metadata_dbt_copied_at: now,
        dw_metadata_filename: filename,
        dw_metadata_file_row_number: (rowNumberCounter += 1),
      }));
      const insert = pgp.helpers.insert(rows, columns);
      await db.none(insert);
      console.log(
        `Lisätty tietokantaan ${partition.length} riviä järjestelmästä ${source}`
      );
    });
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: 'Tietokantaan kirjoittaminen epaonnistui' };
  } finally {
    dbClient.end();
  }

  const duration = Math.round((new Date().getTime() - startTime) / 1000);
  return {
    statusCode: 200,
    body: `Lahde: ${source}, rivien lukumaara: ${contentJson.length}, ajon kesto: ${duration}`,
  };
};

const partition = (array: Array<object>, partitionLen: number): Array<Array<object>> => {
  return array.length
    ? [array.splice(0, partitionLen)].concat(partition(array, partitionLen))
    : [];
};
