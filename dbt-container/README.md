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

## DBT:n threadien määrä
Threadien määrä luetaan `DBT_THREADS_PROD`-ympäristömuuttujasta
(`dbt/profiles.yml`, prod-target). Oletusarvo on `4`, jos muuttujaa ei ole asetettu.

AWS:ssä arvo tulee Parameter Storesta polusta `/<ympäristö>/ecs/dbt-runner/threads`.
