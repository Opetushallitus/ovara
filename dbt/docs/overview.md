{% docs __overview__ %}
# Ovara dbt ohjeistus

## dbt-ajon threadien määrä
Tämä arvo on konfiguroitavissa erikseen testi- ja tuotantoympäristöllle. Arvo on AWS:ssä tallennettu Parameter Store-palveluun arvolla {ympäristö}/ecs/dbt-runner/threads.
Kun tämän arvon muuttaa niin seuraava käynnistyvä dbt-ajo käyttää uutta arvoa

{% enddocs %}