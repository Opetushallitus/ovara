package fi.oph.opintopolku.ovara;

import com.amazonaws.regions.Regions;
import fi.oph.opintopolku.ovara.db.DatabaseToS3;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.stream.Stream;

public class App {

    public static final Logger LOG = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) throws Exception {

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
                LOG.info("Scheman {} taulut: ", tableNames);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });

    }
}
