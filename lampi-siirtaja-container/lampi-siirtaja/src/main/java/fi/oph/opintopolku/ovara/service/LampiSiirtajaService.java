package fi.oph.opintopolku.ovara.service;

import fi.oph.opintopolku.ovara.config.Config;
import fi.oph.opintopolku.ovara.db.DatabaseToS3;
import fi.oph.opintopolku.ovara.db.SchemaExport;
import fi.oph.opintopolku.ovara.db.domain.S3ExportResult;
import fi.oph.opintopolku.ovara.s3.ManifestS3Transfer;
import fi.oph.opintopolku.ovara.s3.SchemaS3Transfer;
import fi.oph.opintopolku.ovara.s3.TableS3Transfer;
import fi.oph.opintopolku.ovara.s3.manifest.Manifest;
import fi.oph.opintopolku.ovara.s3.manifest.Schema;
import fi.oph.opintopolku.ovara.s3.manifest.TableItem;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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

    // List<String> schemaNames = List.of("pub", "dw");
    List<String> schemaNames = List.of("pub");

    schemaNames.forEach(
        schemaName -> {
          try {
            List<TableItem> tableItems = new ArrayList<>();

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

                  TableS3Transfer transfer = new TableS3Transfer(config);

                  try {
                    String versionId =
                        transfer.transferToLampi(filename, uploadFilename, numberOfFiles);
                    tableItems.add(
                        new TableItem(uploadFilename, versionId == null ? "DUMMY" : versionId));
                  } catch (Exception e) {
                    LOG.error("Tiedoston {} siirtäminen Lampeen epäonnistui", filename, e);
                    throw new RuntimeException(e);
                  }
                });

            LOG.info("Exportoidaan schema-määritykset ({})", schemaName);
            SchemaExport schemaExport = new SchemaExport(config);
            String schemaLampiS3Key = config.lampiKeyPrefix() + "ovara-" + schemaName + ".schema";
            File schemaTempFile = schemaExport.exportSchema(schemaNames);

            LOG.info("Siirretään schema-määritykset Lampeen ({})", schemaName);
            SchemaS3Transfer schemaTransfer = new SchemaS3Transfer(config);
            String versionId = schemaTransfer.uploadSchema(schemaLampiS3Key, schemaTempFile);
            Schema schema = new Schema(schemaLampiS3Key, versionId == null ? "DUMMY" : versionId);

            LOG.info("Siirretään manifest.json Lampeen ({})", schemaName);
            Manifest manifest = new Manifest(schema, tableItems);
            String manifestFileName = "manifest-" + schemaName + ".json";
            ManifestS3Transfer manifestTransfer = new ManifestS3Transfer(config);
            manifestTransfer.uploadManifest(manifestFileName, manifest);

            LOG.info("Scheman {} tiedostojen siirto Lammen S3-ämpäriin valmistui", schemaName);
          } catch (Exception e) {
            throw new RuntimeException(e);
          }
        });
  }
}
