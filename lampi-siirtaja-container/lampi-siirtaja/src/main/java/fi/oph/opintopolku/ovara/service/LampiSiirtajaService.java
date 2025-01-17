package fi.oph.opintopolku.ovara.service;

import fi.oph.opintopolku.ovara.config.Config;
import fi.oph.opintopolku.ovara.db.DatabaseToS3;
import fi.oph.opintopolku.ovara.db.domain.S3ExportResult;
import fi.oph.opintopolku.ovara.s3.LampiS3Transfer;
import fi.oph.opintopolku.ovara.s3.manifest.ManifestItem;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LampiSiirtajaService {

  private static final Logger LOG = LoggerFactory.getLogger(LampiSiirtajaService.class);

  private final Config config;

  public LampiSiirtajaService(final Config config) {
    this.config = config;
  }

  public void run() throws Exception {
    DatabaseToS3 db = new DatabaseToS3(config);

    List<ManifestItem> manifestItems = new ArrayList<>();

    Stream.of("pub", "dw")
        // Stream.of("pub")
        .forEach(
            schemaName -> {
              try {
                LOG.info("Haetaan scheman {} taulut", schemaName);
                List<String> tableNames = db.getTableNames(schemaName);
                LOG.info("Scheman {} taulut: {}", schemaName, tableNames);
                LOG.info("Viedään scheman {} datat Ovaran AWS S3-ämpäriin", schemaName);
                Map<String, S3ExportResult> exportToS3Results =
                    db.exportTablesToS3(schemaName, tableNames);
                LOG.info("Scheman {} datojen vienti Ovaran AWS S3-ämpäriin valmistui", schemaName);
                LOG.info("Aloitetaan scheman {} tiedostojen siirto Lammen S3-ämpäriin", schemaName);
                exportToS3Results.forEach(
                    (tableName, s3ExportResult) -> {
                      int numberOfFiles = s3ExportResult.getFiles_uploaded();

                      String filename = String.format("%s.csv", tableName);
                      String uploadFilename =
                          String.format("%s%s.gz", config.lampiKeyPrefix(), filename);

                      LampiS3Transfer transfer = new LampiS3Transfer(config);

                      try {
                        String versionId =
                            transfer.transferToLampi(filename, uploadFilename, numberOfFiles);
                        // manifestItems.add(new ManifestItem(uploadFilename, versionId));
                        // Ovaran testiämpärissä ei ole versionti päällä
                        manifestItems.add(
                            new ManifestItem(
                                uploadFilename, versionId == null ? "DUMMY" : versionId));
                      } catch (Exception e) {
                        LOG.error("Manifest-tiedoston siirtäminen Lampeen epäonnistui", e);
                        throw new RuntimeException(e);
                      }
                    });
                LOG.info("Scheman {} tiedostojen siirto Lammen S3-ämpäriin valmistui", schemaName);
              } catch (Exception e) {
                throw new RuntimeException(e);
              }
            });
    LOG.info("Siirretään manifest.json Lampeen");
    LampiS3Transfer manifestTransfer = new LampiS3Transfer(config);
    manifestTransfer.uploadManifest(manifestItems);
  }
}
