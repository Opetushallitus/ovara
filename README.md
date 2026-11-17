# Ovara | Opiskelijavalinnan raportointi


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
