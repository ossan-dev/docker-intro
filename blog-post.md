# Docker: how to build & use your first image

## Hashtags

docker, linux, sql, devops

In this short blog post I'll explain u some basics about Docker. The goal is to build a custom image with a MS SQL Server database and make its sensitive data anonymous 🐱‍💻. If this sounds exciting to u, please stay with me as I walk you through this simple little process. If you get in trouble you can check the files in my GitHub repo linked [here](https://github.com/ivan-pesenti/docker-intro).

## Software requirements

In order to follow this demo u must have Docker installed on your machine. I'm using Docker Desktop for Windows (you could download [here](https://docs.docker.com/docker-for-windows/install/)). I'll recommend u to use Linux containers and set Docker to use WSL - v2 for its engine instead of Hyper-V.  
To test the correctness of the demo u should have installed a client that could connect to SQL Server (I use SQL Server Management Studio).

## Ingredients

These are the only two things needed to complete this post:

1. A backup of a demo database. U can download a sample from [here](https://github.com/ivan-pesenti/docker-intro/blob/master/AdventureWorksLT2017.bak?raw=true)
1. T-SQL script to restore the db and anonymize the data. U can download [here](https://github.com/ivan-pesenti/docker-intro/blob/master/restore-db-and-mask-data.sql)

⭐HINT⭐ _I suggest u to copy this two files in the same directory on your file system._

## Dockerfile building

This is the main part of the blog post so I'll try to deep dive in every statements of the Dockerfile in order to give u a better idea of their usage and options.  
First, u have to create a file called "Dockerfile" in the folder where u placed the two ingredients above (⚠️WARNING⚠️ be sure to **NOT** add any extension to the file, not ".txt", ".json", just "Dockerfile").  
Once you have created the file we can start to edit it.
The first three lines to add are:

```
FROM mcr.microsoft.com/mssql/server:2019-latest as build
ENV ACCEPT_EULA=Y
ENV MSSQL_SA_PASSWORD=abcdABCD1234!
```

The first line will download the SQL Server 2019 image from Docker Hub if it could not be found locally. This image is running on Linux Containers so you must use them in order to follow along.  
In the second and third lines we set two environment variables that we need in order to spin up a SQL Server correctly. Please be sure to provide a policy complaint password for the SA because it could lead to a login error. I'll found that the provided password does its job in this case.

```
WORKDIR /tmp
COPY AdventureWorksLT2017.bak .
COPY restore-db-and-mask-data.sql .
```

Now we've to set the working directory to '/tmp' (you can notice that this is a Linux path as we can run commands inside of a Linux machine).  
The other two statements copy the two files specified ("AdventureWorksLT2017.bak" & "restore-db-and-mask-data.sql") in the working directory so we can use them in future statements.

```
RUN /opt/mssql/bin/sqlservr --accept-eula & sleep 25 \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "abcdABCD1234!" -i /tmp/restore-db-and-mask-data.sql \
    && pkill sqlservr
```

With this statement we started the MS SQL server and we forced it to wait for 25 seconds in order to finish up the necessary startup actions such as starting the system databases, prepare the server to accept client connections and so on. If you find out that this delay is too high or too small per your machine, feel free to adjust it as u wish.  
At the second line we use the SQLCMD utility to do a connection via CLI (command-line-interface) and we specify an input file to execute with the flag "-i" followed by the file's path on the target Linux machine. The statement terminates with a command that kills the server.  
🔧BONUS TIP🔧 _in order to split a single command among multiple lines use the combo "\" and "&&"._

```
FROM mcr.microsoft.com/mssql/server:2019-latest as release
ENV ACCEPT_EULA=Y
```

The FROM statement use the same base image as the above FROM statement but now the alias used is "release" instead of "build". This is a multi-staged build. You can find more information [here](https://docs.docker.com/develop/develop-images/multistage-build/). The ENV one is the same as before and it's mandatory to continue as in order to use this product u must accept the end user license agreement.

```
COPY --from=build /var/opt/mssql/data /var/opt/mssql/data
```

This is the last statement of our Dockerfile. With this you'll copy the data file of the database (after the T-SQL script has been run) into a clean base SQL Server image. So our image can be built thanks to this Dockerfile. So, let's go ahead!

## Image building

Now that our Dockerfile is ready to use we can build our user-defined image based on it.  
First you've to open a shell from a terminal (e.g. Windows terminal, the VS Code built-in one, PowerShell and so on) and navigate to the directory with all of the files in this demo. After that you will be able to run this statement:

```
docker build -t my-custom-db .
```

With this instruction you'll build an image called "my-custom-db" with the flag "-t" from a Dockerfile located in the current folder (🔴IMPORTANT❗🔴 **note the "." at the end of the line**). If your Dockerfile is not located in the current folder you've to specify its path otherwise it will result in an error.  
🔎NOTE🔎 _if u run this command multiple times without change anything u'll notice that Docker reuse steps from cache instead of rebuild them blindly. This is an amazing time savings that Docker will bring in our life._

## Run a container

The final step is to spin up a container based on our custom image and check if everything is working fine.

The command is the following:

```
docker run -p 11433:1433 -d my-custom-db
```

The flag "-p" indicates the mapping between the host's port (11433) and the container's port (1433). "-d" stands for **detached mode**, that is the terminal will not listen for any input/output commands but the container still run in background.

## Testing

The testing phase is divided in two parts.

### Check if containers is running

To check if the container is up and running u can issue this command in the terminal:

```
docker ps -a
```

"docker ps" is used to list the active and running containers. The flag "-a" stands for "all", so we're able to see both running & non-running containers.

### Check if database has the correct data

To check if the data are those expected u can try to connect to MS SQL Server with a SQL client. In my case I used SQL Server Management Studio. My connection parameters were:

- server name: localhost,11433
- username: sa
- password: abcdABCD1234!

When you connect to the server you can find a database named AdventureWorks. In it you can check if the table "Customer" has no sensitive data. Et voilà! No more sensitive data in your table. The activity has been successful 😄.

## Conclusion

Now you are able to build your user-defined image and do some simple stuff with Docker. One use-case is when you have to deal with backup that contain sensitive data. U cannot show them to anyone else. One way to achieve it could be this method so you can still work with consistent data while not exposing confidential info. In this post we only scratched the surface of Docker, there is plenty of other things that are worth to be aware of. This blog post is based upon a talk that you can see [here](https://youtu.be/xUR6Dcuopcw) .

I hope you enjoy this post and find it useful. If you have any questions or you want to spot me some errors I really appreciate it and I'll make my best to follow up. If you enjoy it and would like to sustain me consider giving a like and sharing on your favorite socials.
Stay safe and see you soon! 😎
