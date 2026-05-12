{{
  config (
    materialized = 'table',
    post_hook = [
        """create index if not exists idx_proxy_pohjakoulutus
            on {{ this }} (hakuoid)
        where keyvalues ? 'POHJAKOULUTUS'; """
        ]
    )
}}

with source as (
    select * from {{ ref('dw_sure_proxysuoritus') }}
)

select * from source
