package fi.oph.opintopolku.ovara;

public record Config (
    String postgresHost,
    Integer postgresPort,
    String postgresUser,
    String postgresPassword,
    String ovaraS3Bucket,
    String lampiS3Bucket,
    String awsRegion
) { }
