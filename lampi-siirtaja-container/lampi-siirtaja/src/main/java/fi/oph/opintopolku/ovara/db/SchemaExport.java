package fi.oph.opintopolku.ovara.db;

import fi.oph.opintopolku.ovara.config.Config;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SchemaExport {

  private static final Logger LOG = LoggerFactory.getLogger(SchemaExport.class);

  private final Config config;

  public SchemaExport(Config config) {
    this.config = config;
  }

  public File exportSchema(List<String> schemaNames) {
    int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LOG.info("Aloitetaan schema export (yritys {}/{})", attempt, maxRetries);
        return doExportSchema(schemaNames);
      } catch (Exception e) {
        LOG.warn(
            "Schema export epäonnistui (yritys {}/{}): {}", attempt, maxRetries, e.getMessage());
        if (attempt == maxRetries) {
          throw new RuntimeException(
              "Ovaran scheman export epäonnistui " + maxRetries + " yrityksen jälkeen", e);
        }
      }
    }
    throw new RuntimeException("Ovaran scheman export epäonnistui");
  }

  private File doExportSchema(List<String> schemaNames) throws Exception {
    File tempFile = File.createTempFile("ovara-", ".schema");
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
    commandList.add("-f");
    commandList.add(tempFile.getAbsolutePath());
    commandList.add("ovara");
    ProcessBuilder processBuilder = new ProcessBuilder(commandList);
    processBuilder.redirectErrorStream(true);
    processBuilder.environment().put("PGPASSWORD", config.postgresPassword());

    LOG.info(
        "Schema export command: {}",
        String.join(" ", processBuilder.command().toArray(new String[0])));

    Process process = processBuilder.start();
    process.waitFor();
    String output = new String(process.getInputStream().readAllBytes());
    LOG.info("Schema export output: {}", output);
    return tempFile;
  }
}
