# This script resets the database by executing a SQL file within a Docker container.

import os
import platform
import sys
import subprocess
import uuid

_use_dev_database = True  # Set to False for production
if _use_dev_database:
    _container_name = os.getenv("STAGESS_DATABASE_DEV_DOCKER")
    _database = os.getenv("STAGESS_DATABASE_DEV_NAME")
    _user = os.getenv("STAGESS_DATABASE_DEV_USER")
    _password = os.getenv("STAGESS_DATABASE_DEV_PASSWORD")
else:
    raise ValueError(
        "This script is intended for development use only.\n"
        "If you REALLY want to reset the production database, comment this line and restart the script."
    )
    # For production, you might want to change this to your production database name
    _database = os.getenv("STAGESS_DATABASE_PRODUCTION_NAME")
    _container_name = os.getenv("STAGESS_DATABASE_PRODUCTION_DOCKER")
    _user = os.getenv("STAGESS_DATABASE_PRODUCTION_USER")
    _password = os.getenv("STAGESS_DATABASE_PRODUCTION_PASSWORD")

if not _database or not _user or not _password:
    print("Environment variables for database configuration are not set.")
    sys.exit(1)

_sql_command = os.getenv("STAGESS_SQL_COMMAND")
if not _sql_command:
    print("Environment variable STAGESS_SQL_COMMAND is not set.")
    sys.exit(1)

_base_command = f"{_sql_command} -vvv -u {_user} -p{_password} {_database}"
if _container_name:
    _base_command = f"docker exec -i {_container_name} { _base_command }"


def main(super_admin_email: str):
    # Get the path to the SQL file
    sql_filename = "reset_database.sql"
    sql_file_path = os.path.join(os.path.dirname(__file__), sql_filename)

    # Check if the SQL file exists
    if not os.path.exists(sql_file_path):
        print(f"SQL reset file ({sql_filename}) not found: {sql_file_path}")
        sys.exit(1)

    # Reset the database
    if not reset_database(sql_file_path):
        print("Failed to reset the database.")
        return
    print("Database reset successfully.")

    # Add an admin user
    if not add_super_admin_user(super_admin_email=super_admin_email):
        print("Failed to add admin user.")
        return
    print("Admin user added successfully.")


def reset_database(sql_filepath: str) -> bool:
    # Run the command to reset the database
    if platform.system() == "Windows":
        with open(sql_filepath, "rb") as sql_file:
            result = subprocess.run(
                _base_command.split(), stdin=sql_file, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
    else:
        cmd = f"cat {sql_filepath} | {_base_command}"
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    # Check if the command was successful
    if result.returncode == 0:
        return True
    else:
        print(result.stderr)
        return False


def add_super_admin_user(super_admin_email: str) -> bool:
    # Use uuid v4 to generate a random ID
    id = str(uuid.uuid4())

    query = f"INSERT INTO entities (shared_id) " f"VALUES ('{id}');"
    if not _perform_query(query):
        return False

    query = f"INSERT INTO admins (id, school_board_id, school_id, access_level) " f"VALUES ('{id}', '', '',  6);"
    if not _perform_query(query):
        return False

    query = f"INSERT INTO users (id, email) " f"VALUES ('{id}', '{super_admin_email}');"
    if not _perform_query(query):
        return False

    query = (
        f"INSERT INTO persons (id, first_name, last_name, email) "
        f"VALUES ('{id}', 'Super', 'Admin', '{super_admin_email}');"
    )
    if not _perform_query(query):
        return False

    query = f"INSERT INTO phone_numbers (id, entity_id, phone_number) " f"VALUES ('{uuid.uuid4()}', '{id}', '');"
    if not _perform_query(query):
        return False

    return True


def _perform_query(query: str) -> bool:
    # Run the query against the database
    cmd = f'{_base_command} -e "{query}"'
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print(f"Error executing query: {result.stderr}")
        return False
    return True


if __name__ == "__main__":
    # Get the super admin email from STAGESS_SUPERADMIN_EMAIL environment variable
    super_admin_email = os.getenv("STAGESS_SUPERADMIN_EMAIL")
    if not super_admin_email:
        print("Environment variable STAGESS_SUPERADMIN_EMAIL is not set.")
        sys.exit(1)

    main(super_admin_email=super_admin_email)
