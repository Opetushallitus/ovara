import PgClient from 'pg-native';
import { NodeJsClient } from '@smithy/types';
import {
  S3Client,
  GetObjectCommand,
  GetObjectCommandOutput,
  PutObjectCommand,
  PutObjectCommandOutput,
  CompleteMultipartUploadCommandOutput,
  CreateMultipartUploadCommand,
  CreateMultipartUploadCommandOutput, UploadPartCommand, UploadPartCommandOutput, CompleteMultipartUploadCommand,
} from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';

import MultiStream from 'multistream';
import { PassThrough, Readable } from 'node:stream';

const dbHost = process.env.POSTGRES_HOST;
const dbUsername = process.env.DB_USERNAME;
const dbPassword = process.env.DB_PASSWORD;
const lampiS3Bucket = process.env.LAMPI_S3_BUCKET;
const ovaraLampiSiirtajaBucket = process.env.OVARA_LAMPI_SIIRTAJA_BUCKET;

const dbUri = `postgresql://${dbUsername}:${dbPassword}@${dbHost}:5432/ovara`;

const validateParameters = () => {
  if(!dbHost) throw Error("Tietokannan osoite puuttuu");
  if(!dbUsername) throw Error("Tietokannan käyttäjänimi puuttuu");
  if(!dbPassword) throw Error("Tietokannan salasana puuttuu");
  if(!lampiS3Bucket) throw Error("Lammen S3-ampärin nimi puuttuu");
}

type ManifestItem = {
  key: string;
  s3Version: string;
};

const getTableNames = (schemaName: string): string[] => {

  const sql = `
    select table_name 
    from information_schema.tables
    where table_schema = '${schemaName}';
  `;

  const pgClient = new PgClient();
  pgClient.connectSync(dbUri);
  const rows = pgClient.querySync(sql);

  return rows.map(row => row.table_name);
}

const copyTableToS3 = (schemaName: string, tableName: string): number => {
  const sql = `
    select *
    from aws_s3.query_export_to_s3(
        'select * from ${schemaName}.${tableName}',
        aws_commons.create_s3_uri(
            '${ovaraLampiSiirtajaBucket}', 
            '${tableName}.csv', 
            'eu-west-1'
        ),
        options := 'FORMAT CSV, HEADER TRUE' 
    );
  `;
  const pgClient = new PgClient();
  pgClient.connectSync(dbUri);
  const queryResult = pgClient.querySync(sql);
  console.log(`QueryResult: ${JSON.stringify(queryResult, null, 4)}`);
  const result = queryResult[0] || {};
  console.log(`Taulun ${tableName} kopioinnin tulos | Rivien määrä:  ${result.rows_uploaded} | Tiedostojen määrä: ${result.files_uploaded} | Tiedostojen koko: ${result.bytes_uploaded}`);
  if(result.files_uploaded !== '1') console.error(`Scheman ${schemaName} taulusta ${tableName} muodostui S3-ämpäriin useampi kuin yksi tiedosto (${result.files_uploaded})`);
  return result.files_uploaded;
}

const copyFileToLampi = async (sourceKey: string, numberOfFiles: number): Promise<ManifestItem> => {
  const ovaraS3Client: S3Client = new S3Client({}) as NodeJsClient<S3Client>;
  const lampiS3Client: S3Client = new S3Client({}) as NodeJsClient<S3Client>;
  const destinationKey = sourceKey;

  console.log(`${sourceKey} | tiedostojen määrä: ${numberOfFiles}`);

  //let contentLength = 0;
  const streams = [];
  for(let i = 1; i <= numberOfFiles; i++) {
    const partSourceKey = i === 1 ? sourceKey : `${sourceKey}_part${i}`;
    console.log(`${sourceKey} | partSourceKey: ${partSourceKey}`);


    if(i === 1) {
      const getObjectCommandOutput: GetObjectCommandOutput = await ovaraS3Client.send(
        new GetObjectCommand({
          Bucket: ovaraLampiSiirtajaBucket,
          Key: partSourceKey,
        }),
      );
      streams.push(getObjectCommandOutput.Body);
    } else {
      streams.push(async () => {
        const getObjectCommandOutput: GetObjectCommandOutput = await ovaraS3Client.send(
          new GetObjectCommand({
            Bucket: ovaraLampiSiirtajaBucket,
            Key: partSourceKey,
          }),
        );
        return getObjectCommandOutput.Body;
      });
    }
    //contentLength = contentLength + getObjectCommandOutput.ContentLength;
  }

  const bodyStream = new MultiStream(streams);
  const passThrough = new PassThrough();
  bodyStream.pipe(passThrough);

  const createMultipartUploadCommand: CreateMultipartUploadCommand = new CreateMultipartUploadCommand({
    Bucket: lampiS3Bucket,
    Key: destinationKey,
    ContentType: 'text/csv'
  });

  const createMultipartUploadCommandOutput: CreateMultipartUploadCommandOutput = await lampiS3Client.send(createMultipartUploadCommand);
  const uploadId = createMultipartUploadCommandOutput.UploadId;

  let i = 1;
  const parts = [];
  while (true) {
    const { done, value } = await passThrough.read(103809024); // 99 MB
    if (done) {
      break;
    } else {
      const uploadPartCommand: UploadPartCommand = new UploadPartCommand({
        Bucket: lampiS3Bucket,
        Key: destinationKey,
        PartNumber: i++,
        UploadId: uploadId,
        Body: value
      });

      const uploadPartCommandOutput: UploadPartCommandOutput = await lampiS3Client.send(uploadPartCommand);
      parts.push(uploadPartCommandOutput.ETag);
    }
  }

  const completeMultipartUploadCommand: CompleteMultipartUploadCommand = new CompleteMultipartUploadCommand({
    Bucket: lampiS3Bucket,
    Key: destinationKey,
    UploadId: uploadId,
    MultipartUpload: {
      Parts: parts
    }
  });

  const completeMultipartUploadCommandOutput: CompleteMultipartUploadCommandOutput = await lampiS3Client.send(completeMultipartUploadCommand);

  /*
  const target = {
    Bucket: lampiS3Bucket,
    Key: destinationKey,
    Body: passThrough,
    ContentLength: contentLength,
    ContentType: 'text/csv'
  }

  const parallelS3Upload = new Upload({
    client: lampiS3Client,
    queueSize: 4, // rinnakkaisuus
    partSize: 524288000, // 500MB
    leavePartsOnError: false,
    params: target,
  });

  const completeMultipartUploadCommandOutput: CompleteMultipartUploadCommandOutput = await parallelS3Upload.done();
  */

  console.log(`Siirretty ${ovaraLampiSiirtajaBucket}/${sourceKey} => ${lampiS3Bucket}/${destinationKey}`);

  return {
    key: destinationKey,
    s3Version: completeMultipartUploadCommandOutput.VersionId
  };
}

const uploadManifestToLampi = async (manifest: ManifestItem[]) => {
  const lampiS3Client: S3Client = new S3Client({});
  const destinationKey = 'manifest.json';

  await lampiS3Client.send(new PutObjectCommand({
    Bucket: lampiS3Bucket,
    Key: destinationKey,
    Body: JSON.stringify(manifest, null, 4)
  }));
}

const main = async () => {
  validateParameters();

  console.log(`Aloitetaan Ovaran tietojen kopiointi Lampeen`);
  console.log(`Tietokannan konfiguraatio: ${dbUri}`.replace(dbPassword, '*****'));

  //const schemaNames = ['pub', 'dw'];
  // Tilapäisesti vain dw schema
  const schemaNames = ['dw'];
  const manifest: ManifestItem[] = [];

  for (const schemaName of schemaNames) {

    console.log(`Aloitetaan scheman "${schemaName}" taulujen siirtäminen Lampeen`);
    const tableNames: string[] = getTableNames(schemaName);
    console.log(`Table names: ${tableNames}`);

    for (const tableName of tableNames) {
      console.log(`Aloitetaan scheman "${schemaName}" taulun "${tableName}" siirtäminen tietokannasta Ovaran S3-ämpäriin`);
      const numberOfFiles = copyTableToS3(schemaName, tableName);
      console.log(`Scheman "${schemaName}" taulun "${tableName}" siirtäminen tietokannasta Ovaran S3-ämpäriin valmistui`);

      const sourceKey = `${tableName}.csv`;
      console.log(`Aloitetaan scheman "${schemaName}" taulun "${tableName}" siirtäminen Ovaran S3-ämpäristä Lammen S3-ämpäriin (key: "${sourceKey}")`);
      const manifestItem = await copyFileToLampi(sourceKey, numberOfFiles);
      console.log(`Scheman "${schemaName}" taulun "${tableName}" siirtäminen Ovaran S3-ämpäristä Lammen S3-ämpäriin valmistui (key: "${sourceKey}")`);
      manifest.push(manifestItem);
    }
    console.log(`Scheman "${schemaName}" taulujen siirtäminen Lampeen valmistui`);
  }
  console.log(`Aloitetaan manifest-tiedoston siirtäminen Lampeen`)
  await uploadManifestToLampi(manifest);
  console.log(`Aloitetaan manifest-tiedoston siirtäminen Lampeen valmistui`)
}

main().then(() => console.log('Ovaran tietojen siirtäminen Lampeen valmistui'));
