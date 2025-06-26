FROM postgrest/postgrest AS postgrest
FROM postgres:15

COPY --from=postgrest /postgrest /usr/local/bin/postgrest
COPY sql/mcp_postgrest--0.1.0.sql /docker-entrypoint-initdb.d/
COPY mcp_postgrest.control /usr/share/postgresql/15/extension/
COPY postgrest.conf.template /etc/

CMD ["sh", "-c", "postgres & sleep 5 && postgrest /etc/postgrest.conf.template"]
