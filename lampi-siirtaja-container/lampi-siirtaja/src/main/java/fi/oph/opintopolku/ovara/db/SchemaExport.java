package fi.oph.opintopolku.ovara.db;

import fi.oph.opintopolku.ovara.config.Config;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SchemaExport {

  private static final Logger LOG = LoggerFactory.getLogger(SchemaExport.class);

  private final Config config;
  private final String schemaFilename;

  public SchemaExport(Config config) {
    this.config = config;
    this.schemaFilename = config.schemaLocation() + config.schemaFilename();
  }

  public String exportSchema(List<String> schemaNames) {
    // String command = "pg_dump -h raportointi.db.ovara.testiopintopolku.fi -p 5432 -U app -W -b
    // -Fc --section=pre-data --section=post-data --no-comments  --no-privilege --no-owner --schema
    // pub --schema int ovara > /tmp/ovara.schema";
    try {
      List<String> commandList =
          Stream.of(
                  "pg_dump",
                  "-h",
                  config.postgresHost(),
                  "-p",
                  config.postgresPort().toString(),
                  "-U",
                  config.postgresUser(),
                  "-b",
                  "-Fc",
                  "--section=pre-data",
                  "--section=post-data",
                  "--no-comments",
                  "--no-privilege",
                  "--no-owner")
              .collect(Collectors.toCollection(ArrayList::new));
      for (String schemaName : schemaNames) {
        commandList.add("--schema");
        commandList.add(schemaName);
      }
      commandList.add("ovara");
      commandList.add(">");
      commandList.add(schemaFilename);
      ProcessBuilder processBuilder = new ProcessBuilder(commandList);
      processBuilder.redirectErrorStream(true);
      processBuilder.environment().put("PGPASSWORD", config.postgresPassword());

      Process process = processBuilder.start();

      process.waitFor();

      String output = new String(process.getInputStream().readAllBytes());
      LOG.info("Schema export output: {}", output);
    } catch (Exception e) {
      throw new RuntimeException("Error exporting schema", e);
    }
    return schemaFilename;
  }
}
