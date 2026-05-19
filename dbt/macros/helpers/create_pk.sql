{% macro create_pk(column) %}
    DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = '{{ this.identifier }}_pk'
        ) THEN
            ALTER TABLE {{ this }}
            ADD CONSTRAINT {{ this.identifier }}_pk
            PRIMARY KEY ({{ column }});
        END IF;
    END $$;

{% endmacro%}