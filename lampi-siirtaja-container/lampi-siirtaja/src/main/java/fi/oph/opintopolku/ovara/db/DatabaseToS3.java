package fi.oph.opintopolku.ovara.db;

import fi.oph.opintopolku.ovara.Config;
import fi.oph.opintopolku.ovara.db.domain.S3ExportResult;
import fi.oph.opintopolku.ovara.db.domain.Table;
import org.apache.commons.dbutils.DbUtils;
import org.apache.commons.dbutils.QueryRunner;
import org.apache.commons.dbutils.ResultSetHandler;
import org.apache.commons.dbutils.handlers.BeanHandler;
import org.apache.commons.dbutils.handlers.BeanListHandler;
import org.javatuples.Pair;

import java.sql.*;
import java.util.List;
import java.util.stream.Collectors;

public class DatabaseToS3 {

    private final Config config;

    public DatabaseToS3(Config config) throws Exception {
        this.config = config;
        Class.forName("org.postgresql.Driver");
    }

    private static final String GET_TABLE_NAMES_SQL = """
        select table_name as tablename
        from information_schema.tables
        where table_schema = ?;
    """;

    private static final String EXPORT_TABLE_TO_S3_SQL = """
        select *
        from aws_s3.query_export_to_s3(
            'select * from ?',
            aws_commons.create_s3_uri(
                ?, 
                ?, 
                ?
            ),
            options := 'FORMAT CSV, HEADER TRUE' 
        );    
    """;

    public List<String> getTableNames(String schemaName) throws Exception{
        ResultSetHandler<List<Table>> h = new BeanListHandler<Table>(Table.class);

        Connection connection = getConnection();
        try {

            QueryRunner run = new QueryRunner();
            List<Table> tables = run.query(connection, GET_TABLE_NAMES_SQL, h, schemaName);

            return tables.stream().map(Table::getTablename).toList();

        } finally {
            DbUtils.close(connection);
        }

    }

    public List<Pair<String, S3ExportResult>> exportTablesToS3(String schemaName, List<String> tableNames) throws Exception {
        List<Pair<String, S3ExportResult>> results = tableNames.stream().map(tableName -> {
            try {
                return exportTableToS3(schemaName, tableName);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }).toList();
        return results;
    }

    private Pair<String, S3ExportResult> exportTableToS3(String schemaName, String tableName) throws Exception {
        ResultSetHandler<S3ExportResult> h = new BeanHandler<S3ExportResult>(S3ExportResult.class);

        Connection connection = getConnection();
        try {

            QueryRunner run = new QueryRunner();
            S3ExportResult s3ExportResult = run.query(
                    connection,
                    EXPORT_TABLE_TO_S3_SQL,
                    h,
                    String.format("%s.%s", schemaName, tableName),
                    config.ovaraS3Bucket(),
                    String.format("%s.csv", tableName),
                    config.awsRegion());

            return new Pair<>(tableName, s3ExportResult);

        } finally {
            DbUtils.close(connection);
        }
    }

    private Connection getConnection() throws Exception {
        return DriverManager.getConnection(String.format("jdbc:postgresql://%s:%s/ovara", config.postgresHost(), config.postgresPort()), config.postgresUser(), config.postgresPassword());
    }

}
