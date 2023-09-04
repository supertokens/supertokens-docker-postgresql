#!/bin/bash

# Get the current value of DATABASE_URL
database_url="$DATABASE_URL"

# Use sed to replace "postgres" with "postgresql" and store the result in a new variable
new_database_url="$(echo "$database_url" | sed 's/postgres/postgresql/')"

# Export the updated value back to the environment variable
export DATABASE_URL="$new_database_url"

# Verify the updated value
echo "Updated DATABASE_URL: $DATABASE_URL"
