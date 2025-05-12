package fi.oph.opintopolku.ovara.s3.manifest;

import java.util.List;

public record Manifest(Schema schema, List<TableItem> tables) {}
