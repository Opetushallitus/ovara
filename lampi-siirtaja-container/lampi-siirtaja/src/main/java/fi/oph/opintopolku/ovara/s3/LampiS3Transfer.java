package fi.oph.opintopolku.ovara.s3;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;
import com.google.common.collect.Iterators;
import fi.oph.opintopolku.ovara.config.Config;
import fi.oph.opintopolku.ovara.io.MultiInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;
import java.util.stream.IntStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LampiS3Transfer {

  private static final Logger LOG = LoggerFactory.getLogger(LampiS3Transfer.class);

  private static final int UPLOAD_PART_SIZE = 99 * 1024 * 1024;
  private static final ExecutorService executor = Executors.newSingleThreadExecutor();

  private final Config config;
  private final AmazonS3 ovaraS3Client;
  private final AmazonS3 lampiS3Client;
  private final AtomicInteger uploadPartId = new AtomicInteger(0);

  private String uploadId;

  public LampiS3Transfer(Config config) {
    this.config = config;
    this.ovaraS3Client = AmazonS3ClientBuilder.standard().build();
    this.lampiS3Client = AmazonS3ClientBuilder.standard().build();
  }

  private Supplier<S3ObjectInputStream> constructSupplier(String downloadFilename) {
    return () ->
        ovaraS3Client.getObject(config.ovaraS3Bucket(), downloadFilename).getObjectContent();
  }

  private PartETag submitTaskForUploading(
      String uploadFilename, ByteArrayInputStream inputStream, boolean isFinalPart) {
    int eachPartId = uploadPartId.incrementAndGet();
    UploadPartRequest uploadRequest =
        new UploadPartRequest()
            .withBucketName(config.lampiS3Bucket())
            .withKey(uploadFilename)
            .withUploadId(uploadId)
            .withPartNumber(eachPartId)
            .withPartSize(inputStream.available())
            .withInputStream(inputStream);

    if (isFinalPart) {
      uploadRequest.withLastPart(true);
    }

    LOG.info(
        "Lähetetään tiedoston {} palanen {} jonka koko on {}",
        uploadFilename,
        eachPartId,
        inputStream.available());

    UploadPartResult uploadResult = lampiS3Client.uploadPart(uploadRequest);

    LOG.info("Lähetetty tiedoston {} palanen {}", uploadFilename, eachPartId);
    return uploadResult.getPartETag();
  }

  public String transferToLampi(String filename, int numberOfFiles) throws Exception {

    LOG.info(
        "Aloitetaan tiedoston {} lähettäminen Lammen S3-ämpäriin joka on {} palassa",
        filename,
        numberOfFiles);

    ObjectMetadata metadata = new ObjectMetadata();
    metadata.setContentType("text/csv");
    InitiateMultipartUploadRequest initRequest =
        new InitiateMultipartUploadRequest(config.lampiS3Bucket(), filename)
            .withObjectMetadata(metadata);
    InitiateMultipartUploadResult initResult = lampiS3Client.initiateMultipartUpload(initRequest);

    uploadId = initResult.getUploadId();

    List<Supplier<S3ObjectInputStream>> streamsFList =
        IntStream.rangeClosed(1, numberOfFiles)
            .mapToObj(
                fileNumber -> {
                  String downloadFilename =
                      fileNumber == 1 ? filename : String.format("%s_part%s", filename, fileNumber);
                  return constructSupplier(downloadFilename);
                })
            .toList();

    Enumeration<Supplier<S3ObjectInputStream>> streams =
        Iterators.asEnumeration(streamsFList.iterator());

    InputStream inputStream = new MultiInputStream(streams);

    int bytesRead, bytesAdded = 0;
    byte[] data = new byte[UPLOAD_PART_SIZE];
    ByteArrayOutputStream bufferOutputStream = new ByteArrayOutputStream();
    List<PartETag> parts = new ArrayList<>();

    while ((bytesRead = inputStream.read(data, 0, data.length)) != -1) {
      bufferOutputStream.write(data, 0, bytesRead);

      if (bytesAdded < UPLOAD_PART_SIZE) {
        bytesAdded += bytesRead;
        continue;
      }
      PartETag partETag =
          submitTaskForUploading(
              filename, new ByteArrayInputStream(bufferOutputStream.toByteArray()), false);
      parts.add(partETag);
      bufferOutputStream.reset(); // flush the bufferOutputStream
      bytesAdded = 0; // reset the bytes added to 0
    }

    PartETag partETag =
        submitTaskForUploading(
            filename, new ByteArrayInputStream(bufferOutputStream.toByteArray()), true);
    parts.add(partETag);

    CompleteMultipartUploadRequest completeRequest =
        new CompleteMultipartUploadRequest(config.lampiS3Bucket(), filename, uploadId, parts);
    CompleteMultipartUploadResult completeMultipartUploadResult =
        lampiS3Client.completeMultipartUpload(completeRequest);

    LOG.info("Tiedoston {} lähettäminen Lammen S3-ämpäriin valmistui", filename);

    return completeMultipartUploadResult.getVersionId();
  }
}
