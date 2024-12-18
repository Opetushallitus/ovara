import PgClient from 'pg-native';

const dbHost = process.argv[2];
const dbUsername = process.argv[3];
const dbPassword = process.argv[4];
const lampiS3Baucket = process.argv[5];

const dbUri = `postgresql://${dbUsername}:${dbPassword}@${dbHost}:5432/ovara`;

const validateCommandlineArgs = () => {
  if(!dbHost) throw Error("Tietokannan osoite puuttuu");
  if(!dbUsername) throw Error("Tietokannan käyttäjänimi puuttuu");
  if(!dbPassword) throw Error("Tietokannan salasana puuttuu");
  if(!lampiS3Baucket) throw Error("Lammen S3-ampärin nimi puuttuu");
}

const getTables = (schemaName: String) => {

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

const main = async () => {
  validateCommandlineArgs();
  console.log(`Tietokanta-URI: ${dbUri}`.replace(dbPassword, '*****'));
}

main();
