#!/usr/bash

# Make sure Docker is installed
sudo snap install docker
# Start the Docker service
sudo snap start docker

# Make sure Docker Compose is reinstalled
docker-compose down

# Start the Docker container for the database
cd dev
docker-compose up -d
cd ../production
docker-compose up -d
cd ..

# Reset the database
# Run the python script `reset_database.py`
