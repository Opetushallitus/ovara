package fi.oph.opintopolku.ovara.db.domain;

public class S3ExportResult {
    private Long rows_uploaded;
    private Long files_uploaded;
    private Long bytes_uploaded;

    public Long getRows_uploaded() {
        return rows_uploaded;
    }

    public void setRows_uploaded(Long rows_uploaded) {
        this.rows_uploaded = rows_uploaded;
    }

    public Long getFiles_uploaded() {
        return files_uploaded;
    }

    public void setFiles_uploaded(Long files_uploaded) {
        this.files_uploaded = files_uploaded;
    }

    public Long getBytes_uploaded() {
        return bytes_uploaded;
    }

    public void setBytes_uploaded(Long bytes_uploaded) {
        this.bytes_uploaded = bytes_uploaded;
    }

    @Override
    public String toString() {
        return "S3ExportResult{" +
                "rows_uploaded=" + rows_uploaded +
                ", files_uploaded=" + files_uploaded +
                ", bytes_uploaded=" + bytes_uploaded +
                '}';
    }
}
