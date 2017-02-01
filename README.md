PaintOmics3 Docker Image
===================
The [PaintOmics3](https://github.com/fikipollo/paintomics3) [Docker](http://www.docker.io) Image is an easy distributable full-fledged PaintOmics3 installation.

PaintOmics3 was developed as part of the [STATegra Project](http://www.stategra.eu), which has received funding from the European Union’s FP7 research and innovation programme.

# Build the image <a name="install" />
The docker image for PaintOmics3 can be found in the [docker hub](https://hub.docker.com/r/fikipollo/paintomics3/). However, you can rebuild is manually by running **docker build**.

```sh
sudo docker build -t paintomics3 .
```
Note that the current working directory must contain the Dockerfile file.

# Running the PaintOmics3 <a name="run" />
The recommended way for running your PaintOmics3 docker is using the provided **docker-compose** script that resolves the dependencies and make easier to customize your instance. Alternatively you can run the docker manually. In both cases the first time that you access to your PaintOmics3 instance the system will be auto-installed. You can easily customize the installation by changing some system variables, you can find the list of available variables in the next section.

## Using the docker-compose file
Launching your PaintOmics3 docker is really easy using docker-compose. Just download the *docker-compose.yml* file and customize the content according to your needs. There are few settings that should be change in the file, follow the instructions in the file to configure your container.
To launch the container, type:
```sh
sudo docker-compose up
```
Using the *-d* flag you can launch the containers in background.

In case you do not have the Container stored locally, docker will download it for you.

# Install the image <a name="install" />
You can run manually your containers using the following commands:

```sh
sudo docker run --name paintomics3-mongo -v /your/data/location/mongo:/data/db -d mongo
sudo docker run --name paintomics3-server -e ADMIN_EMAIL=admin@paintomics.es --link paintomics3-mongo -v /your/data/location:/data/paintomics3 -p 8080:80 -d fikipollo/paintomics3
```

In case you do not have the Container stored locally, docker will download it for you.

A short description of the parameters would be:
- `docker run` will run the container for you.

- `-p 8080:80` will make the port 80 (inside of the container) available on port 8080 on your host.
    Inside the container an Apache2 Webserver is running on port 80 and that port can be bound to a local port on your host computer.
    With this parameter you can access to the PaintOmics3 instance via `http://localhost:8080` immediately after executing the command above.

- `fikipollo/paintomics3` is the Image name, which can be found in the [docker hub](https://hub.docker.com/r/fikipollo/paintomics3/).

- `-d` will start the docker container in daemon mode.

- `-e VARIABLE_NAME=VALUE` changes the default value for a system variable.
The PaintOmics3 docker accepts the following variables that modify the **INSTALLATION** of the system in the docker.

- **ADMIN_EMAIL**, the email for the admin account (default value is *admin@paintomics.es*).
- **ADMIN_PASS**, the password for the admin account MUST BE HASHED USING SHA1 (default value is *123*).
- **ADMIN_AFFILIATION**, the affiliation for the user account.

For an interactive session, you can execute :

```sh
sudo docker exec -it paintomics3-server bash
```
