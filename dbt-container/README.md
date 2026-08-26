# DBT-ajojen Docker-kontti

## Kontin build
```
./build.sh
```

## Kontin käynnistäminen
```
docker run --rm --name dbt-runner ovara-dbt-runner
```

## Kontin käynnistäminen lisäparametreilla
Kontille annetut argumentit välitetään sellaisenaan `dbt build` -komennolle:
```
docker run --rm --name dbt-runner ovara-dbt-runner --select tag:my_tag --exclude my_model
```

Ajossa AWS:ssä parametrit annetaan GitHub Actions -workflowlla
`Run DBT Runner with parameters`, joka välittää ne ECS-taskin
`containerOverrides.command`-kentässä.
