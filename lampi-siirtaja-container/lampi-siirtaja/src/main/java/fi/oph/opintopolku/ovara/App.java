package fi.oph.opintopolku.ovara;

import com.amazonaws.regions.Regions;
import fi.oph.opintopolku.ovara.db.DatabaseToS3;
import fi.oph.opintopolku.ovara.db.domain.S3ExportResult;
import fi.oph.opintopolku.ovara.s3.LampiS3Transfer;
import fi.oph.opintopolku.ovara.s3.manifest.ManifestItem;
import org.javatuples.Pair;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

public class App {

    public static final Logger LOG = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) throws Exception {

        LOG.info("Aloitetaan Ovaran tietojen siirto Lampeen");

        Config config = new Config(
                System.getenv("POSTGRES_HOST"),
                Integer.valueOf(System.getenv("POSTGRES_PORT")),
                System.getenv("DB_USERNAME"),
                System.getenv("DB_PASSWORD"),
                System.getenv("OVARA_LAMPI_SIIRTAJA_BUCKET"),
                System.getenv("LAMPI_S3_BUCKET"),
                Regions.EU_WEST_1.getName()
        );

        DatabaseToS3 db = new DatabaseToS3(config);

        Stream.of("pub").forEach(schemaName -> {
            try {
                LOG.info("Haetaan scheman {} taulut", schemaName);
                List<String> tableNames = db.getTableNames("pub");
                LOG.info("Scheman {} taulut: {}", schemaName, tableNames);
                LOG.info("Viedään scheman {} datat Ovaran AWS S3-ämpäriin", schemaName);
                List<Pair<String, S3ExportResult>> exportToS3Results = db.exportTablesToS3(schemaName, tableNames);
                LOG.info("Scheman {} datojen vienti Ovaran AWS S3-ämpäriin valmistui", schemaName);
                LOG.info("Aloitetaan scheman {} tiedostojen siirto Lammen S3-ämpäriin", schemaName);
                List<ManifestItem> manifestItems = new ArrayList<>();
                exportToS3Results.forEach(result -> {
                    String tableName = result.getValue0();
                    int numberOfFiles = result.getValue1().getFiles_uploaded();

                    String filename = String.format("%s.csv", tableName);

                    LampiS3Transfer transfer = new LampiS3Transfer(config);

                    try {
                        String versionId = transfer.transferToLampi(filename, numberOfFiles);
                        manifestItems.add(new ManifestItem(filename, versionId));
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                });
                LOG.info("Scheman {} tiedostojen siirto Lammen S3-ämpäriin valmistui", schemaName);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });

        LOG.info("Ovaran tietojen siirto Lampeen valmistui");

    }
}
