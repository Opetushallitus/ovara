{% macro create_pk(column) %}
    do $$
    begin
        if not exists (
            SELECT 1
            FROM pg_constraint c
            JOIN pg_class t
                ON t.oid = c.conrelid
            JOIN pg_namespace n
                ON n.oid = t.relnamespace
            WHERE c.conname = '{{ this.identifier }}_pk'
            AND n.nspname = '{{ this.schema }}'
        ) then
            alter table {{ this }}
            add constraint {{ this.identifier }}_pk
            primary key ({{ column }});
        end if;
    end $$;

{% endmacro%}