#!/bin/bash

if [ ! -d temp ]; then
	mkdir temp
fi

#docker run -d --name=koji-db vrutkovs/koji-db
docker run -d --name=koji-db -e POSTGRES_DB='koji' -e POSTGRES_USER='koji' -e POSTGRES_PASSWORD='mypassword' postgres:9.4

docker run -d --name=koji-hub -v temp:/koji-clients --link koji-db:koji-db vrutkovs/koji-dojo-hub
