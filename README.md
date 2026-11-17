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
pnpm install
```

Corepack käyttää juuren `package.json`-tiedostoon lukittua pnpm-versiota.
`pnpm install` asentaa molempien projektien riippuvuudet yhteisestä `pnpm-lock.yaml`-tiedostosta.
Riippuvuuksia muutetaan esimerkiksi komennolla `pnpm --filter ./cdk add <paketti>`;
commitoi myös päivitetty lukitustiedosto.

```sh
pnpm --filter ./cdk run build
pnpm --filter ./cdk test --runInBand
pnpm --filter ./utility/cdk run build
pnpm --filter ./utility/cdk test --runInBand
```

Deploy-skriptit käyttävät projekteihin asennettua CDK-versiota. Niiden `-d`-valitsin
asentaa riippuvuudet lukitustiedoston mukaisesti.

## Ajastetut kontit
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

## Ajastetut kontit
