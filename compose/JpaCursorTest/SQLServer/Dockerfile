FROM mcr.microsoft.com/mssql/server:2022-latest

ENV DB_NAME=DB

USER root

RUN mkdir -p /usr/config/initdb.d \
    && chown -R mssql:mssql /usr/config \
    && chmod -R +x /usr/config/initdb.d

COPY ./initdb.d /usr/config/initdb.d

USER mssql

WORKDIR /usr/config/initdb.d

ENTRYPOINT ["/bin/sh", "-c", "/usr/config/initdb.d/entrypoint.sh"]
