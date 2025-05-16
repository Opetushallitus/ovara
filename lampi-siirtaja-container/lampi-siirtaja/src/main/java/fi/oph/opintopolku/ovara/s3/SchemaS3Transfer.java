package fi.oph.opintopolku.ovara.s3;

import fi.oph.opintopolku.ovara.config.Config;
import java.io.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.model.*;

public class SchemaS3Transfer extends AbstractLampiS3Transfer {

  private static final Logger LOG = LoggerFactory.getLogger(SchemaS3Transfer.class);

  public SchemaS3Transfer(Config config) {
    super(config);
  }

  public String uploadSchema(String lampiFileKey, File schemaTempFile) throws Exception {
    FileInputStream fileInputStream = new FileInputStream(schemaTempFile);

    LOG.info("Schema (temp): {}", schemaTempFile.getAbsolutePath());
    LOG.info("Schema (key): {}", lampiFileKey);

    PutObjectRequest putObjectRequest =
        PutObjectRequest.builder().bucket(config.lampiS3Bucket()).key(lampiFileKey).build();

    RequestBody requestBody =
        RequestBody.fromInputStream(fileInputStream, fileInputStream.available());

    PutObjectResponse putObjectResponse = lampiS3Client.putObject(putObjectRequest, requestBody);

    return putObjectResponse.versionId();
  }
}
