package fi.oph.opintopolku.ovara.s3;

import com.google.gson.Gson;
import fi.oph.opintopolku.ovara.config.Config;
import software.amazon.awssdk.auth.credentials.ContainerCredentialsProvider;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sts.StsClient;
import software.amazon.awssdk.services.sts.auth.StsAssumeRoleCredentialsProvider;
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest;

public abstract class AbstractLampiS3Transfer {

  protected final Config config;
  protected final S3Client ovaraS3Client;
  protected final S3Client lampiS3Client;
  protected final Gson gson;

  public AbstractLampiS3Transfer(Config config) {
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
  }
}
