package fi.oph.opintopolku.ovara.s3;

import fi.oph.opintopolku.ovara.config.Config;
import fi.oph.opintopolku.ovara.s3.manifest.Manifest;
import java.io.*;
import java.nio.charset.StandardCharsets;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.model.*;

public class ManifestS3Transfer extends AbstractLampiS3Transfer {

  private static final Logger LOG = LoggerFactory.getLogger(ManifestS3Transfer.class);

  public ManifestS3Transfer(Config config) {
    super(config);
  }

  public void uploadManifest(String manifiestFilename, Manifest manifest) throws Exception {
    String uploadFilename = config.lampiKeyPrefix() + manifiestFilename;

    String json = gson.toJson(manifest);
    InputStream inputStream = new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8));

    LOG.info("Manifest S3: {}", manifiestFilename);
    LOG.info("Manifest: {}", json);

    PutObjectRequest putObjectRequest =
        PutObjectRequest.builder().bucket(config.lampiS3Bucket()).key(uploadFilename).build();

    RequestBody requestBody = RequestBody.fromInputStream(inputStream, inputStream.available());

    lampiS3Client.putObject(putObjectRequest, requestBody);
  }
}
