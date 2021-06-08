# Learn Docker in 5 steps

## Hashtags

docker, linux, sql

In this short blog post I'll try to explain u some basics about Docker. The goal is to build a custom image with a MS SQL Server database with anonymous data. If this sounds exciting to u, please stay with me I walk you through this simple little process. If you get in trouble you can check the files in the GitHub repo linked [here](https://github.com/ivan-pesenti/docker-intro).

## Prerequisites

1. Docker installed
1. A SQL client
1. File .bak [AdventureWorksLT2017](https://github.com/ivan-pesenti/docker-intro/blob/master/AdventureWorksLT2017.bak?raw=true)
1. T-SQL script to restore the db and anonymize the data. You can download [here](https://github.com/ivan-pesenti/docker-intro/blob/master/restore-db-and-mask-data.sql)

## Dockerfile building

This is the main part of the blog post so I'll try to deep dive in every statements of the Dockerfile. First, I'll recommend u to copy the .bak file and .sql file in the same folder and in it create also the Dockerfile (be sure to **NOT** add any extension to the file).
Once you have created the file we can start to edit it.
The first three lines to add are:

```
FROM mcr.microsoft.com/mssql/server:2019-latest as build
ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=abcdABCD1234!
```

The first line will download the SQL Server 2019 image from Docker Hub if it could not be found locally. This image is running on Linux Containers so you must use them in order to follow along.
In the second and third lines we set two environment variable that we need in order to spin up a SQL Server correctly. Please be sure to provide a policy complaint password for the SA because it could lead to a login error. I'll found that the provided password does its job in this case.

```
WORKDIR /tmp
COPY AdventureWorksLT2017.bak .
COPY restore-db-and-mask-data.sql .
```

Now we've to set the working directory to '/tmp' (you can notice that this is a Linux path so we can run command inside of a Linux machine). The other two statements copy the two files specified in the working directory so we can use them in future statements.

```
RUN /opt/mssql/bin/sqlservr --accept-eula & sleep 25 \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "abcdABCD1234!" -i /tmp/restore-db-and-mask-data.sql \
    && pkill sqlservr
```

With this statement we started the MS SQL server and we forced it to wait for 25 seconds in order to finish up the necessary startup actions such as starting the system databases, prepare the server to accept client connections and so on. At the next line (starting with "&&") we use the SQLCMD utility to do a connection via terminal and we specify an input file to execute with the flag "-i" followed by the file's path on the target Linux machine. The statement terminates with a command that kills the server.

```
FROM mcr.microsoft.com/mssql/server:2019-latest as release
ENV ACCEPT_EULA=Y
```

The FROM statement use the same base image as the above one but now the alias used is "release" instead of "build". This is a multi-staged build. You can find more information [here](https://docs.docker.com/develop/develop-images/multistage-build/). The ENV one is the same as before and it's mandatory to continue.

```
COPY --from=build /var/opt/mssql/data /var/opt/mssql/data
```

This is the last statement of our Dockerfile. With this you'll copy the data file of the database (after the T-SQL script has been run) into a clean base SQL Server image.
