# Ovara | Opiskelijavalinnan raportointi

## DBT
Ovara-tietomalli on mallennettu dbt:llä (https://www.getdbt.com)
dbt-core on python-kirjasto jota asennetaan pypistä. Kehityksessä on suositeltu käyttää Pythonin virtualenv:iä. 

Tarvittavat python-kirjastot on listattu dbt/requirements.txt-tiedostossa
```
# pip install -r requirements.txt
```

Tämän lisäksi pitää myös asentaa dbt:n omia paketteja
```
# dbt deps
```

dbt:n configurointi käyttää paikallisia muuttujia, seuraavat pitää määritellä:

| Muuttuja | Selite |
|---|---|
| `POSTGRES_HOST_TEST` | |
| `DBT_USERNAME_TEST` | |
| `DBT_PASSWORD_TEST` | |
| `DBT_PORT_TEST` | |
| `POSTGRES_SCHEMA_TEST` | oma schemasi kehitystä varten |
| `POSTGRES_HOST_PROD` | |
| `DBT_USERNAME_PROD` | |
| `DBT_PASSWORD_PROD` | |
| `DBT_PORT_PROD` | |


Tietokantaan pääsee bastionin kautta, kantojen endpointit näkyvät AWS:ssä

## GitHub
Githubissa on asennusskripteja, ja myös mahdollisuus käynnistää ajot tarvittaessa käsin. 


### Deploy DBT Runner
Asentaa haluttu kontti ajettavaksi
Image tag annetaan muodossa ga-xxx halutun kontin mukaan ja sitten valitaan kohdeympäristö testi/tuotanto. 
Hetken päästä uusi kontti on asennettu, ja seuraaava käynnistys (ajastettu tai manuaalinen) käyttää tätä uutta konttia

### Run DBT Runner
Käynnistää dbt-ajot
Valitse ajettava ympäristö testi/tuotanto. Tämä käynnistää kyseiseen ympäristöön asennettu kontti ja 
ajaa kaikki datat sen koodin mukaisesti. Myös uusi dokumentointi luodaan ja julkaistaan. Tämä on täysin sama kun mikä 
ajastettu käynnistys ajaa

### Run DBT Runner with parameters
Käynnistää dbt ajot parametreilla.
Käynnistettäessä anna ympäristön lisäksi valintainen määrä dbt:n parametreja, esim ```-s gen_toteutus```
Parametrit annetaan samassa muodossa kun komentokehotteesta dbt run.
Ajossa ajetaan ainoastaan nämä annetut parametrit, eikä luoda dokumentaatiota.

Konteissa on tarkistus että ainostaan yksi ajo on kerralla menossa. Jos uutta ajoa yritetään käynnistää kun 
edellinen on vielä käynnistää, tulee tästä virheilmoitus slackiin.


## CDK-kehitysympäristö

CDK-projektien (`cdk` ja `utility/cdk`) riippuvuudet hallitaan yhteisellä pnpm-workspacella.
Ota käyttöön `.nvmrc`-tiedoston Node-versio ja asenna pnpm:

```sh
nvm use
npm install --global corepack
corepack enable
pnpm install --frozen-lockfile
```

Corepack käyttää juuren `package.json`-tiedostoon lukittua pnpm-versiota.
`pnpm install --frozen-lockfile` asentaa molempien projektien riippuvuudet yhteisestä `pnpm-lock.yaml`-tiedostosta.
Riippuvuuksia muutetaan esimerkiksi komennolla `pnpm --filter ./cdk add <paketti>`;
commitoi myös päivitetty lukitustiedosto. Kehitysympäristössä riippuvuuskomennot
saavat päivittää lukitusta; deploy-skriptit asentavat aina `--frozen-lockfile`-valitsimella.

Husky ja esbuild hallitaan workspacen juuressa. Myös lint-staged ajetaan juuresta,
ja se käyttää kullekin tiedostolle lähintä projektikohtaista konfiguraatiota
(`cdk/package.json` tai `utility/cdk/package.json`).

```sh
pnpm --filter ./cdk run build
pnpm --filter ./cdk test --runInBand
pnpm --filter ./utility/cdk run build
pnpm --filter ./utility/cdk test --runInBand
```

Deploy-skriptit käyttävät projekteihin asennettua CDK-versiota. Niiden `-d`-valitsin
asentaa riippuvuudet lukitustiedoston mukaisesti.

## Ajastetut kontit
ECS:ssä on kaksi ajastettua Fargate-taskia. Ajastus ja päälläolo määritellään tiedostossa `cdk/config/<ympäristö>.json`:

| Kontti | Ajastus | Päälle/pois | Käytössä oleva image-tagi (Parameter Store) |
|---|---|---|---|
| DBT Runner | `dbtCron` | `dbtProcessingEnabled` | `/<ympäristö>/ecs/dbt-runner/version` |
| Lampi-siirtäjä | `lampiSiirtajaCron` | `lampiSiirtajaEnabled` | `/<ympäristö>/ecs/lampi-siirtaja/version` |

Cron-ajat tulkitaan UTC-aikana, koska ne ovat EventBridge-sääntöjä. Kun haluat muuttaa ajastusta tai keskeyttää ajastetut ajot,
muuta configia ja deployaa EcsStack (ks. [Deploy](#deploy)).

Kontit buildataan GitHub Actionsilla (`Build DBT Runner Container`, `Build Lampi-siirtäjä Container`). Build käynnistyy automaattisesti,
kun `dbt/`-, `dbt-container/`- tai `lampi-siirtaja-container/`-hakemistoon pushataan muutoksia. Imaget tallennetaan utility-tilin ECR:ään
tagilla `ga-<ajon numero>`. Deploy-workflow rekisteröi uuden task definitionin, päivittää EventBridge-säännöt käyttämään sitä
ja kirjoittaa tagin Parameter Storeen.

### Konttien asennus käsin
Uusi image ei asennu ympäristöön automaattisesti. Asennus tehdään käsin jollakin alla olevista tavoista.

**Asennettavan tagin selvittäminen.** Tagi on buildin `ga-<ajon numero>`. Sen näkee GitHub Actionsin build-ajosta tai ECR:stä:
```
aws ecr describe-images --repository-name ovara-dbt-runner --query 'sort_by(imageDetails,&imagePushedAt)[-5:].imageTags' \
  --profile oph-opiskelijavalinnan-raportointi-utility
```
Lampi-siirtäjän repositorio on `ovara-lampi-siirtaja`. Ympäristössä tällä hetkellä oleva versio:
```
aws ssm get-parameter --name /testi/ecs/dbt-runner/version --query Parameter.Value --profile oph-opiskelijavalinnan-raportointi-qa
```

**1. GitHub Actions (suositeltu).** Workflowt `Deploy DBT Runner` ja `Deploy Lampi-siirtäjä` (ks. [GitHub](#github)).
Ne voi käynnistää myös komentoriviltä:
```
gh workflow run deploy-dbt-runner.yml -f image-tag=ga-123 -f environment=testi
gh workflow run deploy-lampi-siirtaja.yml -f image-tag=ga-45 -f environment=testi
```
Workflow päivittää task definitionin, ajastussäännöt ja Parameter Storen version. Uusi image on käytössä seuraavasta
käynnistyksestä alkaen.

**2. CDK.** Jos GitHub Actions ei ole käytettävissä, päivitä ensin version Parameter Storeen ja deployaa sen jälkeen EcsStack:
```
aws ssm put-parameter --name /testi/ecs/dbt-runner/version --type String --value ga-123 --overwrite \
  --profile oph-opiskelijavalinnan-raportointi-qa
./deploy.sh diff testi EcsStack
./deploy.sh deploy testi EcsStack
```
Lampi-siirtäjän parametri on `/<ympäristö>/ecs/lampi-siirtaja/version`. `deploy.sh`:n `-v`-valitsinkin vaihtaa DBT Runnerin imagen,
mutta se ei päivitä Parameter Storea. Seuraava EcsStackin deploy ilman `-v`:tä palauttaa silloin Parameter Storessa olevan
version, joten käytä mieluummin yllä kuvattua tapaa.

### Konttien käynnistys käsin
Käsin käynnistetty ajo käyttää ympäristöön asennettua uusinta task definitionia ja samoja verkkoasetuksia kuin ajastettu ajo.

**1. GitHub Actions.** Workflowt `Run DBT Runner`, `Run DBT Runner with parameters` ja `Run Lampi-siirtäjä`
(ks. [GitHub](#github)). Komentoriviltä:
```
gh workflow run run-dbt-runner.yml -f environment=testi
gh workflow run run-dbt-runner-with-parameters.yml -f environment=testi -f parameters="--select gen_toteutus+"
gh workflow run run-lampi-siirtaja.yml -f environment=testi
```

**2. Paikallisesti skripteillä.** Workflowt kutsuvat hakemiston `ci-tools/` skriptejä, ja niitä voi ajaa myös omalta koneelta.
Skriptit eivät ota profiilia parametrina, joten anna se `AWS_PROFILE`-muuttujassa:
```
AWS_PROFILE=oph-opiskelijavalinnan-raportointi-qa ci-tools/run-testi-dbt-runner.sh
AWS_PROFILE=oph-opiskelijavalinnan-raportointi-qa ci-tools/run-testi-dbt-runner.sh --select gen_toteutus+
AWS_PROFILE=oph-opiskelijavalinnan-raportointi-qa ci-tools/run-testi-lampi-siirtaja.sh
AWS_PROFILE=oph-opiskelijavalinnan-raportointi-prod ci-tools/run-tuotanto-dbt-runner.sh
```
DBT Runnerin skriptille annetut lisäparametrit välitetään `dbt build` -komennolle. Parametreilla ajettaessa seedit,
siivous ja dokumentaation generointi jätetään väliin.

**Ajon seuranta.** Lokit ovat CloudWatchissa lokiryhmissä `/aws/ecs/task/<ympäristö>-dbt-task` ja
`/aws/ecs/task/<ympäristö>-ovara-lampi-siirtaja`. Käynnissä olevat taskit näet komennolla
```
aws ecs list-tasks --cluster testi-ecs-cluster --profile oph-opiskelijavalinnan-raportointi-qa
```
Käynnissä olevan ajon voi pysäyttää komennolla `aws ecs stop-task --cluster <klusteri> --task <task-id>`.

**Jumiin jäänyt prosessilukko.** Kontit merkitsevät DynamoDB-tauluun `ecsProsessiOnKaynnissa`, että ajo on käynnissä. Jos kontti
pysähtyy kesken (esim. `stop-task` tai muistin loppuminen), lukko voi jäädä tilaan `true`. Silloin jokainen uusi ajo päättyy
virheeseen "Edellinen ajo on vielä käynnissä". Kun olet varmistanut, ettei yhtään taskia ole käynnissä, vapauta lukko:
```
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='false' WHERE prosessi='dbt-scheduled-task'" \
  --profile oph-opiskelijavalinnan-raportointi-qa
```
Lampi-siirtäjän prosessin nimi on `lampi-scheduled-task`.

### DBT
### Lampi-siirto
### Alkuasetukset DynamoDB:hen
Komennot on ajettava kun luodaan uusi ympäristö tai kun halutaan tyhjentää taulut.
#### Testi
```
aws dynamodb execute-statement --statement "INSERT INTO ecsProsessiOnKaynnissa VALUE {'prosessi':'dbt-scheduled-task','onKaynnissa':'false'}" --profile oph-opiskelijavalinnan-raportointi-qa
aws dynamodb execute-statement --statement "INSERT INTO ecsProsessiOnKaynnissa VALUE {'prosessi':'lampi-scheduled-task','onKaynnissa':'false'}" --profile oph-opiskelijavalinnan-raportointi-qa
```
#### Tuotanto
```
aws dynamodb execute-statement --statement "INSERT INTO ecsProsessiOnKaynnissa VALUE {'prosessi':'dbt-scheduled-task','onKaynnissa':'false'}" --profile oph-opiskelijavalinnan-raportointi-prod
aws dynamodb execute-statement --statement "INSERT INTO ecsProsessiOnKaynnissa VALUE {'prosessi':'lampi-scheduled-task','onKaynnissa':'false'}" --profile oph-opiskelijavalinnan-raportointi-prod
```

## Infran ylläpito
Infra on kuvattu AWS CDK:lla (TypeScript) hakemistossa `cdk/`. ECR-repositoriot ovat erillisellä utility-tilillä, ja niiden
CDK-koodi on hakemistossa `utility/cdk/`.

### Ympäristöt
| Ympäristö | AWS-profiili | Domain |
|---|---|---|
| `testi` | `oph-opiskelijavalinnan-raportointi-qa` | `ovara.testiopintopolku.fi` |
| `tuotanto` | `oph-opiskelijavalinnan-raportointi-prod` | `ovara.opintopolku.fi` |
| utility (ECR) | `oph-opiskelijavalinnan-raportointi-utility` | – |

Määrittele profiilit omaan `~/.aws/config`-tiedostoosi täsmälleen näillä nimillä, koska skriptit viittaavat niihin suoraan.
Kaikki resurssit ovat regionissa `eu-west-1`, paitsi CertificateStack, joka on `us-east-1`:ssä.
`cdk/config/kehitys.json` on olemassa, mutta kehitysympäristö ei ole aktiivisessa käytössä.

### Esivaatimukset
- Node.js, pnpm ja CDK-projektien riippuvuudet (ks. [CDK-kehitysympäristö](#cdk-kehitysympäristö))
- AWS CLI v2 ja [Session Manager -plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) bastion-yhteyksiä varten
- `jq`

### Stackit
| Stack | Sisältö |
|---|---|
| `ExternalRolesStack` | GitHub Actionsin OIDC-provider ja deploy-rooli `ovara-<ympäristö>-github-actions-deployment-role` |
| `MonitorStack` | SNS-topic `<ympäristö>-slack-alarm` ja AWS Chatbotin Slack-integraatio |
| `Route53Stack` | Julkinen hosted zone (`publicHostedZone`) |
| `CertificateStack` | Sertifikaatti (`us-east-1`) |
| `NetworkStack` | VPC, aliverkot ja NAT-gatewayt |
| `S3Stack` | Siirtotiedosto-bucket ja SQS-jonot, deployment-bucket, dokumentaatio-bucket |
| `DatabaseStack` | Aurora PostgreSQL, parametriryhmä, varmuuskopiot, PrivateLink-NLB, valvonnat |
| `EcsStack` | ECS-klusteri, DBT Runnerin ja Lampi-siirtäjän ajastetut taskit, DynamoDB-taulu `ecsProsessiOnKaynnissa`, valvonnat |
| `LambdaStack` | Siirtotiedostojen latauslambda ja Lampi-lambdat |
| `BastionStack` | Bastion-autoscaling-ryhmä, NLB ja DNS-nimi `bastion.<domain>` |

Stackien väliset riippuvuudet on määritelty tiedostossa `cdk/bin/cdk.ts`.

### Deploy
Deploy tehdään repon juuresta skriptillä `deploy.sh`:
```
./deploy.sh diff testi EcsStack       # näytä erot ajossa olevaan ympäristöön
./deploy.sh deploy testi EcsStack     # deployaa yksi stack
./deploy.sh deploy testi all          # deployaa kaikki stackit
./deploy.sh -d deploy testi all       # asenna ensin riippuvuudet lukitustiedoston mukaisesti
```

Huomioitavaa:
- Aja aina ensin `diff` ja käy muutokset läpi. Tarkista erityisesti DatabaseStackin ja NetworkStackin muutokset: jos resurssi
  korvataan (replace), data voi kadota tai yhteydet katketa.
- Vie muutos ensin testiin ja vasta sitten tuotantoon.
- `-v ga-xxx` ylikirjoittaa DBT Runnerin image-tagin. Ilman sitä tagi luetaan Parameter Storesta
  (`/<ympäristö>/ecs/dbt-runner/version`), joten CDK-deploy säilyttää GitHub Actionsilla viimeksi deployatun version.
  Lampi-siirtäjän tagi luetaan aina Parameter Storesta. Normaalisti `-v`:tä ei tarvita.
- Synthissä ajetaan [cdk-nag](https://github.com/cdklabs/cdk-nag) (AwsSolutions). Jos tarkistus löytää virheen, deploy pysähtyy.
  Poikkeukset lisätään stackiin `NagSuppressions`-kutsulla, ja jokaiselle poikkeukselle kirjataan perustelu.
- Älä käytä `delete`-komentoa tuotannossa. Aurora on suojattu (`deletionProtection`, `RemovalPolicy.RETAIN`), mutta muut
  resurssit poistuvat stackin mukana.

Utility-tilin ECR-stack deployataan omalla skriptillään:
```
./utility/deploy.sh deploy EcrStack
```

### Ympäristökohtainen konfiguraatio
Asetukset ovat tiedostoissa `cdk/config/<ympäristö>.json`, ja niiden tyypit on määritelty tiedostossa `cdk/lib/config.ts`.

| Avain | Selite |
|---|---|
| `aurora.version` | PostgreSQL-versio (`major` ja `full`) |
| `aurora.writerInstanceType`, `aurora.readerInstanceType` | Instanssityypit |
| `aurora.serverlessReader`, `aurora.minCapacity`, `aurora.maxCapacity` | Serverless v2 -lukijan käyttö ja skaalausrajat (ACU) |
| `aurora.backup.deleteAfterDays` | Varmuuskopioiden säilytysaika |
| `aurora.deletionProtection` | Poistosuojaus |
| `vpc.maxAzs`, `vpc.netGateways` | AZ:iden ja NAT-gatewayden määrä |
| `siirtotiedostot.*` | Lammen ja Ovaran siirtotiedosto-bucketit |
| `lampiFileHandlerActive` | Lampi-tiedostomuutosten käsittely päälle/pois |
| `dbtCron`, `dbtProcessingEnabled` | DBT Runnerin ajastus ja päälläolo |
| `lampiSiirtajaCron`, `lampiSiirtajaEnabled` | Lampi-siirtäjän ajastus ja päälläolo |

### Parameter Store ja Secrets Manager
CDK ei luo alla olevia arvoja. Ne lisätään ympäristöön käsin ennen ensimmäistä deployta.

| Parametri | Selite |
|---|---|
| `/<ympäristö>/aurora/raportointi/master-user-password` | Auroran pääkäyttäjän `oph` salasana (SecureString) |
| `/<ympäristö>/aurora/raportointi/app-user-password` | `app`-käyttäjän salasana, jota dbt ja Lampi-siirtäjä käyttävät (SecureString) |
| `/<ympäristö>/aurora/raportointi/readonly-user-password` | `readonly`-käyttäjän salasana (SecureString) |
| `/<ympäristö>/ecs/dbt-runner/threads` | dbt:n threadien määrä |
| `/<ympäristö>/ecs/dbt-runner/version` | DBT Runnerin image-tagi, päivittyy deploy-workflowssa |
| `/<ympäristö>/ecs/lampi-siirtaja/version` | Lampi-siirtäjän image-tagi, päivittyy deploy-workflowssa |
| `/<ympäristö>/ovara-utility-ovara-dbt-runner-repository-arn` | Utility-tilin ECR-repon ARN |
| `/<ympäristö>/ovara-utility-ovara-lampi-siirtaja-repository-arn` | Utility-tilin ECR-repon ARN |
| `/<ympäristö>/opintopolku-account-id` | Opintopolun AWS-tilin id (siirtotiedostot, PrivateLink) |
| `/<ympäristö>/lampi-role`, `/<ympäristö>/lampi-write-role`, `/<ympäristö>/lampi-external-id` | Lammen roolit ja external id |
| `/<ympäristö>/lambda/lampi-auth-token` | Lampi-lambdan autentikointitoken |
| `/<ympäristö>/monitor/slack-alarm-integration-workspace-id` | Slack-workspacen id |
| `/<ympäristö>/monitor/slack-alarm-integration-channel-id` | Hälytyskanavan id |
| `/<ympäristö>/ovara-wildcard-certificate-arn` | Wildcard-sertifikaatin ARN |

Secrets Managerin salaisuus `bastion/public_keys` sisältää bastionin `authorized_keys`-tiedoston. Bastion hakee sen
15 minuutin välein, joten avaimen lisäys tai poisto astuu voimaan ilman deployta.

GitHub Actions tarvitsee repositorion secreteiksi seuraavat arvot: `AWS_OVARA_UTILITY_ROLE_ARN`, `AWS_OVARA_TESTI_ROLE_ARN`,
`AWS_OVARA_TUOTANTO_ROLE_ARN`, `AWS_OVARA_UTILITY_ECR_DBT_RUNNER_REPO` ja `AWS_OVARA_UTILITY_ECR_LAMPI_SIIRTAJA_REPO`.

### Bastion ja tietokantayhteys
Bastion avaa yhteyden tietokantaan. Yhteys muodostetaan SSM:n kautta skriptillä `tools/ssh.sh`:
```
./tools/ssh.sh testi bash                                                    # shell bastionille
./tools/ssh.sh testi bash 5999:raportointi.db.ovara.testiopintopolku.fi:5432 # tunneli kantaan localhost:5999
```
Vaihtoehtoisesti bastionille pääsee SSH:lla (`ec2-user@bastion.<domain>`) BastionStackissa sallituista IP-osoitteista.
Tämä vaatii, että avaimesi on salaisuudessa `bastion/public_keys`.

Bastion-instanssi korvataan automaattisesti kuukauden ensimmäisenä sunnuntaina klo 3.00 Suomen aikaa, ja uusi instanssi käynnistyy
uusimmalla Amazon Linux 2023 -AMI:lla. Korvauksen voi käynnistää myös käsin:
```
aws autoscaling start-instance-refresh --auto-scaling-group-name <ympäristö>-BastionAutoScalingGroup \
  --preferences MinHealthyPercentage=0 --profile <profiili>
```
Hakemiston `cdk/files/bastion/` skriptit kopioidaan BastionStackin deployssa deployment-bucketiin, ja instanssi hakee ne
käynnistyessään. Jos muutat skriptejä, deployaa BastionStack ja korvaa instanssi.

### Tietokanta
- **Roolit ja käyttäjät:** `tools/update-postgres-db-roles.sh <ympäristö> <tietokanta>` ajaa bastionilla skriptin
  `ensure-psql-roles-up-to-date.sh`. Skripti luo käyttäjät `app`, `readonly`, `insert_raw_user` ja `ovara_app` ja asettaa niiden
  oikeudet.
- **Versiopäivitys:** päivitä `aurora.version` configiin, aja `diff` ja deployaa DatabaseStack. Tee päivitys ensin testissä.
  Pääversion päivitys luo myös parametriryhmän uudelleen ja aiheuttaa käyttökatkon, joten ajoita se dbt-ajojen ulkopuolelle.
- **Varmuuskopiot:** Auroran oma backup retention ja AWS Backupin jatkuva varmuuskopio (`<ympäristö>-ovara-backup-vault`),
  säilytysaika `aurora.backup.deleteAfterDays`. Palautus tehdään AWS Backupin tai RDS:n konsolista uuteen klusteriin.
- Auroran tapahtumat (RDS cluster- ja instance-eventit) välittyvät Slackiin.

### Valvonta
Hälytykset ohjataan SNS-topiciin `<ympäristö>-slack-alarm`, josta AWS Chatbot välittää ne Slack-kanavalle. Hälytys tulee, kun
- Auroran CPU-käyttö on yli 95 % (15 minuutin keskiarvo)
- DBT Runner- tai Lampi-siirtäjä-ajo epäonnistuu
- kontin käynnistys epäonnistuu tai kontti päättyy virhekoodiin
- ajoa yritetään käynnistää, kun edellinen on vielä käynnissä.

### Riippuvuuksien päivitys
Renovate päivittää ainoastaan GitHub Actionsien versiot (`renovate.json`). CDK:n ja lambdojen riippuvuudet
(`cdk/package.json`, `utility/cdk/package.json`) päivitetään käsin pnpm:llä, ja myös päivitetty `pnpm-lock.yaml` commitoidaan.
Päivityksen jälkeen aja build ja testit (ks. [CDK-kehitysympäristö](#cdk-kehitysympäristö)), tarkista muutokset
`diff`-komennolla ja deployaa ensin testiin.
