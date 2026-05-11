# Accessing the database

One must request the `backendFirebaseServiceAccountKey.json` file from the administrator of the database. This file must be placed in the ROOT directory of the project.
NOTE: This is true as long as the authentication is done using Firebase.

# Docker basics

## Linux

### Install

You can install docker using snap:
`sudo snap install docker`

Then you have to run the service:
`sudo snap start docker`

### Windows

You can install docker using the installer provided by Docker, then you restart your computer.
The service will be started automatically.

# Debug

If you are developping, you may want to run your own version of the database. 
To do so, use the `docker-compose.yml` file provide by running the following command from the ROOT/database/[dev or production] directory:
`docker-compose up -d`

To stop the database, you can run the following command:
`docker-compose down`

NOTE: Please note that the production directory does not directly contain the `docker-compose.yml` file, but rather a `docker-compose.yml.default` file which must be copy-pasted and filled to `docker-compose.yml` before running the command.

To interact with the database, you can run the following command: 
`docker exec -it stagess_dev mariadb -u devuser -p`

To inspect the database the database by exporting the full content of which, you can run the following command:
`docker exec stagess_dev sh -c 'exec mariadb-dump -udevuser -pdevpassword dev_db' > dump.sql`

# Database structure

## Tables 

The see the database structure, please refer to `reset_database.sql` file.
This file contains the SQL commands to create the database and all the tables.


## Reset the database

To reset the database, you can run the following command:
`docker exec -i stagess_dev mariadb -u devuser -pdevpassword < reset_database.sql`
Make sure not to put space between the `-p` and the password.
This will drop the database and create it again with the tables defined in the `reset_database.sql` file.


# Expected error messages

## Error 1054
`Database failure: Unknown column 'COLUMN_NAME' in 'field list' (1054).`

This is pretty self explanatory. This probably means the backend was updated, but not the database.


## Error 1156
`Database failure: Got packets out of order (1156). This should not happen, please contact the administrator of the database.`

It seems that this can happen when the database has not created the tables yet.


## The operator "<" is reserved for future use

This error occurs when trying to update the database using the reset_database.sql file.
It is a Windows specific error when using PowerShell. 
The solution is not to use PowerShell.
