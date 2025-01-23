package fi.oph.opintopolku.ovara.config;

import software.amazon.awssdk.regions.Region;

public record Config(
    String postgresHost,
    Integer postgresPort,
    String postgresUser,
    String postgresPassword,
    String ovaraS3Bucket,
    String lampiS3Bucket,
    Region awsRegion,
    String lampiKeyPrefix,
    String lampiRoleArn,
    String lampiRoleSessionName,
    String lampiExternalId) {}
