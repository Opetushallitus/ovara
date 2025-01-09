import PgClient from 'pg-native';
import { NodeJsClient } from '@smithy/types';
import {
  S3Client,
  GetObjectCommand,
  GetObjectCommandOutput,
  PutObjectCommand,
  PutObjectCommandOutput, CompleteMultipartUploadCommandOutput,
} from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';

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

const copyTableToS3 = (schemaName: string, tableName: string) => {
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
  console.log(`Taulun ${tableName} kopioinnin tulos | Rivien määrä:  ${queryResult.rows_uploaded} | Tiedostojen määrä: ${queryResult.files_uploaded} | Tiedostojen koko: ${queryResult.bytes_uploaded}`);
  if(queryResult.files_uploaded !== '1') console.error(`Scheman ${schemaName} taulusta ${tableName} muodostui S3-ämpäriin useampi kuin yksi tiedosto (${queryResult.files_uploaded})`);
}

const copyFileToLampi = async (sourceKey: string): Promise<ManifestItem> => {
  const ovaraS3Client: S3Client = new S3Client({}) as NodeJsClient<S3Client>;
  const lampiS3Client: S3Client = new S3Client({}) as NodeJsClient<S3Client>;
  const destinationKey = sourceKey;

  const getObjectCommandOutput: GetObjectCommandOutput = await ovaraS3Client.send(
    new GetObjectCommand({
      Bucket: ovaraLampiSiirtajaBucket,
      Key: sourceKey,
    }),
  );

  /*
  const putObjectCommandOutput: PutObjectCommandOutput = await lampiS3Client.send(
    new PutObjectCommand({
      Bucket: lampiS3Bucket,
      Key: destinationKey,
      Body: getObjectCommandOutput.Body,
      ContentLength: getObjectCommandOutput.ContentLength,
      ContentType: 'text/csv'
    })
  );
  */
  const target = {
    Bucket: lampiS3Bucket,
    Key: destinationKey,
    Body: getObjectCommandOutput.Body,
    ContentLength: getObjectCommandOutput.ContentLength,
    ContentType: 'text/csv'
  }

  const parallelUploads3 = new Upload({
    client: lampiS3Client,
    queueSize: 4, // rinnakkaisuus
    partSize: 524288000, // 500MB
    leavePartsOnError: false,
    params: target,
  });

  const completeMultipartUploadCommandOutput: CompleteMultipartUploadCommandOutput = await parallelUploads3.done();

  console.log(`Siirretty ${ovaraLampiSiirtajaBucket}/${sourceKey} => ${lampiS3Bucket}/${destinationKey}`);

  return {
    key: destinationKey,
    s3Version: completeMultipartUploadCommandOutput.VersionId
    //s3Version: putObjectCommandOutput.VersionId
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

  const schemaNames = ['pub', 'dw'];
  const manifest: ManifestItem[] = [];

  for (const schemaName of schemaNames) {

    console.log(`Aloitetaan scheman "${schemaName}" taulujen siirtäminen Lampeen`);
    const tableNames: string[] = getTableNames(schemaName);
    console.log(`Table names: ${tableNames}`);

    for (const tableName of tableNames) {
      console.log(`Aloitetaan scheman "${schemaName}" taulun "${tableName}" siirtäminen tietokannasta Ovaran S3-ämpäriin`);
      copyTableToS3(schemaName, tableName);
      console.log(`Scheman "${schemaName}" taulun "${tableName}" siirtäminen tietokannasta Ovaran S3-ämpäriin valmistui`);

      const sourceKey = `${tableName}.csv`;
      console.log(`Aloitetaan scheman "${schemaName}" taulun "${tableName}" siirtäminen Ovaran S3-ämpäristä Lammen S3-ämpäriin (key: "${sourceKey}")`);
      const manifestItem = await copyFileToLampi(sourceKey);
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
