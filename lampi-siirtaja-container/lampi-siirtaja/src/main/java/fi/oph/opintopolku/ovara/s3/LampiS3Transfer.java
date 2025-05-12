package fi.oph.opintopolku.ovara.s3;

import com.google.common.collect.Iterators;
import com.google.gson.Gson;
import fi.oph.opintopolku.ovara.config.Config;
import fi.oph.opintopolku.ovara.io.MultiInputStream;
import fi.oph.opintopolku.ovara.s3.manifest.Manifest;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Supplier;
import java.util.stream.IntStream;
import java.util.zip.GZIPOutputStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.auth.credentials.ContainerCredentialsProvider;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.sts.StsClient;
import software.amazon.awssdk.services.sts.auth.StsAssumeRoleCredentialsProvider;
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest;

public class LampiS3Transfer {

  private static final Logger LOG = LoggerFactory.getLogger(LampiS3Transfer.class);

  private static final int UPLOAD_PART_SIZE = 99 * 1024 * 1024;
  private static final String MANIFEST_FILENAME = "manifest.json";

  private final Config config;
  private final S3Client ovaraS3Client;
  private final S3Client lampiS3Client;
  private final AtomicInteger uploadPartId = new AtomicInteger(0);
  private final Gson gson;

  private String uploadId;

  public LampiS3Transfer(Config config) {
    this.config = config;
    this.gson = new Gson();
    this.ovaraS3Client =
        S3Client.builder()
            .region(config.awsRegion())
            .credentialsProvider(ContainerCredentialsProvider.create())
            .build();

    StsClient stsClient =
        StsClient.builder()
            .region(config.awsRegion())
            .credentialsProvider(ContainerCredentialsProvider.create())
            .build();

    AssumeRoleRequest assumeRoleRequest =
        AssumeRoleRequest.builder()
            .roleArn(config.lampiRoleArn())
            .roleSessionName(config.lampiRoleSessionName())
            .externalId(config.lampiExternalId())
            .build();

    this.lampiS3Client =
        S3Client.builder()
            .region(config.awsRegion())
            .credentialsProvider(
                StsAssumeRoleCredentialsProvider.builder()
                    .stsClient(stsClient)
                    .refreshRequest(assumeRoleRequest)
                    .build())
            .build();

    /*
    this.lampiS3Client =
        S3Client.builder()
            .region(config.awsRegion())
            .credentialsProvider(ContainerCredentialsProvider.create())
            .build();
     */
  }

  private Supplier<ResponseInputStream<GetObjectResponse>> constructSupplier(
      String downloadFilename) {
    return () -> {
      GetObjectRequest getObjectRequest =
          GetObjectRequest.builder().bucket(config.ovaraS3Bucket()).key(downloadFilename).build();
      return ovaraS3Client.getObject(getObjectRequest);
    };
  }

  public void startGZIPCompressing(OutputStream out, InputStream in) {
    try (GZIPOutputStream gOut = new GZIPOutputStream(out)) {
      byte[] buffer = new byte[10240];
      int len;
      while ((len = in.read(buffer)) != -1) {
        gOut.write(buffer, 0, len);
      }
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    } finally {
      try {
        out.close();
      } catch (Exception e) {
        LOG.error("GZIP-pakkauksen streamin sulkeminen epäonnistui", e);
      }
    }
  }

  private CompletedPart submitTaskForUploading(
      String uploadFilename, ByteArrayInputStream inputStream, boolean isFinalPart) {
    int eachPartId = uploadPartId.incrementAndGet();
    UploadPartRequest uploadRequest =
        UploadPartRequest.builder()
            .bucket(config.lampiS3Bucket())
            .key(uploadFilename)
            .uploadId(uploadId)
            .partNumber(eachPartId)
            .build();

    RequestBody requestBody = RequestBody.fromInputStream(inputStream, inputStream.available());

    LOG.info(
        "Lähetetään tiedoston {} palanen {} jonka koko on {}",
        uploadFilename,
        eachPartId,
        inputStream.available());

    UploadPartResponse uploadPartResponse = lampiS3Client.uploadPart(uploadRequest, requestBody);

    LOG.info("Lähetetty tiedoston {} palanen {}", uploadFilename, eachPartId);

    CompletedPart completedPart =
        CompletedPart.builder().partNumber(eachPartId).eTag(uploadPartResponse.eTag()).build();

    return completedPart;
  }

  public String transferToLampi(String filename, String uploadFilename, int numberOfFiles)
      throws Exception {

    LOG.info(
        "Aloitetaan tiedoston {} lähettäminen Lammen S3-ämpäriin joka on {} palassa",
        filename,
        numberOfFiles);

    CreateMultipartUploadRequest createRequest =
        CreateMultipartUploadRequest.builder()
            .bucket(config.lampiS3Bucket())
            .key(uploadFilename)
            .contentType("text/csv")
            .contentEncoding("gzip")
            .build();

    CreateMultipartUploadResponse createResponse =
        lampiS3Client.createMultipartUpload(createRequest);

    uploadId = createResponse.uploadId();

    List<Supplier<ResponseInputStream<GetObjectResponse>>> streamsFList =
        IntStream.rangeClosed(1, numberOfFiles)
            .mapToObj(
                fileNumber -> {
                  String downloadFilename =
                      fileNumber == 1 ? filename : String.format("%s_part%s", filename, fileNumber);
                  return constructSupplier(downloadFilename);
                })
            .toList();

    Enumeration<Supplier<ResponseInputStream<GetObjectResponse>>> streams =
        Iterators.asEnumeration(streamsFList.iterator());

    InputStream multiInputStream = new MultiInputStream(streams);

    final PipedOutputStream pipedOutputStream = new PipedOutputStream();
    PipedInputStream pipedInputStream = new PipedInputStream();
    pipedInputStream.connect(pipedOutputStream);

    Thread thread = new Thread(() -> startGZIPCompressing(pipedOutputStream, multiInputStream));
    thread.start();

    int bytesRead, bytesAdded = 0;
    byte[] data = new byte[UPLOAD_PART_SIZE];
    ByteArrayOutputStream bufferOutputStream = new ByteArrayOutputStream();
    List<CompletedPart> completedParts = new ArrayList<>();

    while ((bytesRead = pipedInputStream.read(data, 0, data.length)) != -1) {
      bufferOutputStream.write(data, 0, bytesRead);

      if (bytesAdded < UPLOAD_PART_SIZE) {
        bytesAdded += bytesRead;
        continue;
      }
      CompletedPart completedPart =
          submitTaskForUploading(
              uploadFilename, new ByteArrayInputStream(bufferOutputStream.toByteArray()), false);
      completedParts.add(completedPart);
      bufferOutputStream.reset(); // flush the bufferOutputStream
      bytesAdded = 0; // reset the bytes added to 0
    }

    CompletedPart completedPart =
        submitTaskForUploading(
            uploadFilename, new ByteArrayInputStream(bufferOutputStream.toByteArray()), true);
    completedParts.add(completedPart);

    CompleteMultipartUploadRequest completeRequest =
        CompleteMultipartUploadRequest.builder()
            .bucket(config.lampiS3Bucket())
            .key(uploadFilename)
            .uploadId(uploadId)
            .multipartUpload(CompletedMultipartUpload.builder().parts(completedParts).build())
            .build();
    CompleteMultipartUploadResponse completeMultipartUploadResult =
        lampiS3Client.completeMultipartUpload(completeRequest);

    LOG.info("Tiedoston {} lähettäminen Lammen S3-ämpäriin valmistui", filename);

    return completeMultipartUploadResult.versionId();
  }

  public String uploadSchema(String lampiFileKey, String tmpFilename) throws Exception {
    File file = new File(tmpFilename);
    FileInputStream fileInputStream = new FileInputStream(file);

    PutObjectRequest putObjectRequest =
        PutObjectRequest.builder().bucket(config.lampiS3Bucket()).key(lampiFileKey).build();

    RequestBody requestBody =
        RequestBody.fromInputStream(fileInputStream, fileInputStream.available());

    PutObjectResponse putObjectResponse = lampiS3Client.putObject(putObjectRequest, requestBody);

    return putObjectResponse.versionId();
  }

  public void uploadManifest(Manifest mainifest) throws Exception {
    String uploadFilename = config.lampiKeyPrefix() + MANIFEST_FILENAME;

    String json = gson.toJson(mainifest);
    InputStream inputStream = new ByteArrayInputStream(json.getBytes(StandardCharsets.UTF_8));

    LOG.info("Manifest: {}", json);

    PutObjectRequest putObjectRequest =
        PutObjectRequest.builder().bucket(config.lampiS3Bucket()).key(uploadFilename).build();

    RequestBody requestBody = RequestBody.fromInputStream(inputStream, inputStream.available());

    lampiS3Client.putObject(putObjectRequest, requestBody);
  }
}
