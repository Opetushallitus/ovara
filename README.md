# Ovara | Opiskelijavalinnan raportointi


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
