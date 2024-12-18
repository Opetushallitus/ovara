import PgClient from 'pg-native';

const dbHost = process.env.POSTGRES_HOST;
const dbUsername = process.env.DB_USERNAME;
const dbPassword = process.env.DB_PASSWORD;
const lampiS3Bucket = process.env.LAMPI_S3_BUCKET;

const dbUri = `postgresql://${dbUsername}:${dbPassword}@${dbHost}:5432/ovara`;

const validateParameters = () => {
  if(!dbHost) throw Error("Tietokannan osoite puuttuu");
  if(!dbUsername) throw Error("Tietokannan käyttäjänimi puuttuu");
  if(!dbPassword) throw Error("Tietokannan salasana puuttuu");
  if(!lampiS3Bucket) throw Error("Lammen S3-ampärin nimi puuttuu");
}

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

const copyTableToS3 = (tableName: string) => {
  const sql = `
    select *
    from aws_s3.query_export_to_s3(
        'select * from ${tableName}',
        aws_commons.create_s3_uri('${lampiS3Bucket}', '${tableName}.csv', 'eu-west-1'),
        options := 'FORMAT CSV, HEADER TRUE' 
    );
  `;
  const pgClient = new PgClient();
  pgClient.connectSync(dbUri);
  const result = pgClient.querySync(sql);
  console.log(`S3 copy result for table ${tableName}: ${JSON.stringify(result, null, 4)}`);
}

const main = async () => {
  validateParameters();
  console.log(`Tietokanta-URI: ${dbUri}`.replace(dbPassword, '*****'));
  console.log(`Lampi S3-ämpäri: ${lampiS3Bucket}`);
  const tableNames: string[] = getTableNames('pub');
  console.log(`Table names: ${tableNames}`);
  tableNames.slice(0, 2).forEach((tableName: string) => {
    copyTableToS3(tableName);
  });
}

main();
