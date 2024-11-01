#!/bin/bash

set -euo pipefail

if [ -z "$MYSQL_HOST" ] ||  [ -z "$MYSQL_PORT" ] ||[ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_DB_NAME" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_BUCKET" ] || [ -z "$R2_S3_ENDPOINT" ]; then
    echo "Missing required environment variables."
    exit 1
fi

# Creates MySQL dump filename
DUMP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql.gz"  # Define DUMP_FILE

# Create MySQL config file with credentials
MYSQL_CNF=$(mktemp)
cat > "$MYSQL_CNF" << EOF
[client]
host=$MYSQL_HOST
port=$MYSQL_PORT
user=$MYSQL_USER
password=$MYSQL_PASSWORD
protocol=tcp
EOF

# Wait for MySQL to be ready
max_tries=30
counter=0
until mysqladmin --defaults-file="$MYSQL_CNF" ping 2>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $max_tries ]; then
        echo "Error: MySQL did not become ready in time"
        exit 1
    fi
    echo "Waiting for MySQL to be ready... ($counter/$max_tries)"
    sleep 2
done

# Creates Gzip MySQL dump file
mysqldump --defaults-file="$MYSQL_CNF" --protocol=tcp "$MYSQL_DB_NAME" | gzip > $DUMP_FILE

# Removes temporary config file
rm "$MYSQL_CNF"

if [ $? -ne 0 ]; then
    echo "Database dump failed."
    exit 1
fi

# Ensures rclone config directory exists
mkdir -p ~/.config/rclone

# Defines rclone.conf content
CONFIG_CONTENT=$(cat <<EOL
[remote]
type = s3
provider = Cloudflare
access_key_id = $R2_ACCESS_KEY_ID
secret_access_key = $R2_SECRET_ACCESS_KEY
endpoint = $R2_S3_ENDPOINT
acl = private
EOL
)

# Writes rclone.conf content
echo "$CONFIG_CONTENT" > ~/.config/rclone/rclone.conf

# Check if the file was created successfully
if [ -f ~/.config/rclone/rclone.conf ]; then
    echo "rclone.conf created successfully."
else
    echo "Error: Failed to create rclone.conf"
    exit 1
fi

# Creates bucket if it doesn't exist
rclone mkdir remote:$R2_BUCKET

# Copies backup file to R2
rclone copyto $DUMP_FILE remote:$R2_BUCKET/mysql-backup/$DUMP_FILE

# Checks rclone exit status
if [ $? -eq 0 ]; then
    echo "Backup file copied successfully to R2."
    # Cleans up local backup file
    rm $DUMP_FILE
    exit 0
else
    echo "Error: Failed to copy backup file to R2."
    exit 1
fi
