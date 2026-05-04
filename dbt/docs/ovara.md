{% docs __ovara__ %}
# Ovara

Tämä sivusto sisältää Ovara-tietokannan ja mallien dokumentaation.

## Skeemat
Tietokannassa on seuraavat skeeman, ja alla on myös kuvattu näiden skeemojen eri käyttöä

### stg
Tämä skeema on ensimmäinen vaihe käsittelyssä. Tähän luetaan siirtotiedostoista tulevat tiedostot sellaisenaan. Skeemassa voi olla duplikaattirivejä jos sama objekti on lähetetty useampaan kertaan ilman että dbt on ajettu välissä.

Tämä skeema myös tyhjennetään jokaisen ajon jälkeen.

### dw

Tähän skeeman kerätään objektien eri versiot ja niiden historia. Tässä tieto on pääsääntöäisesti objektitunniste-muutosaikaleima-tasolla. Eli samasta objektista on tallessa useampi rivi.
Tähän skeemaan luettaessa käsitellään myös duplikaattiriviä, niin että tässä skeemassa jokainen objekti-muutoshetki-rivi löytyy ainoastaan kerran vaikka se olisi tllut siirtotiedostosta moneen kertaan.

### int1

Tässä skeemassa on tiedot pääsääntöisesti samalla tasolla kun dw-skeemassa sillä erolla että tässä skeemassa on aina vaan viimeisin rivi. Eli dw-skeemasta aina haettu se objektin rivi jossa on tuorein muutosaikaleima.

Tässä skeemassa yhden taulun sisältö tulee edelleen yhdeltä siirtotiedostolta

### int

Tämä skeema sisältää logiikkaa ja laskentoja joista ei sinänsä oikein ole mielenkiintoa loppukäuyttäjälle. Tässä skeemassa on malli jos se helpottaa/selkeyttää jonkin tietyn logiikan laskeminen, tai jos logiikka tarvitaan useaan eri malliin

### pub

Tämä skeema on tarkoitettu OPintopolun raportoinnin käyttöön. Tiedot ovat hyvin pitkälle optimoitu raportointikäyttöä varten, ja tietosisältö on ainoastaan se jota tarvitaan raportointia varten

### gen

Tämä skeema on tarkoitettu tietojen luovutusta varten. Tähän on erilaista tietoa purettu auki ja yhdistelty, mutta tauluissa on silti lähes kaikki lähdejärjestelmien tietoja


{% enddocs %}