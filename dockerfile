FROM mcr.microsoft.com/mssql/server:2019-latest as build
ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=abcdABCD1234!

WORKDIR /tmp
COPY AdventureWorksLT2017.bak .
COPY restore-db-and-mask-data.sql .

RUN /opt/mssql/bin/sqlservr --accept-eula & sleep 25 \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "abcdABCD1234!" -i /tmp/restore-db-and-mask-data.sql \
    && pkill sqlservr

FROM mcr.microsoft.com/mssql/server:2019-latest as release
ENV ACCEPT_EULA=Y

COPY --from=build /var/opt/mssql/data /var/opt/mssql/data
