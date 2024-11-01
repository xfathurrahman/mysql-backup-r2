#!/bin/bash

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
user=$MYSQL_USER
password=$MYSQL_PASSWORD
EOF

# Creates Gzip MySQL dump file
mysqldump --defaults-file="$MYSQL_CNF" "$MYSQL_DB_NAME" | gzip > $DUMP_FILE

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
[bucket-name]
type = s3
provider = AWS
access_key_id = $R2_ACCESS_KEY_ID
secret_access_key = $R2_SECRET_ACCESS_KEY
region = auto
endpoint = $R2_S3_ENDPOINT
acl = private
location_constraint =auto
server_side_encryption = AES256
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
rclone mkdir bucket-name:$R2_BUCKET

# Copies backup file to R2
rclone copyto $DUMP_FILE bucket-name:$R2_BUCKET/$DUMP_FILE

# Checks rclone exit status
if [ $? -eq 0 ]; then
    echo "Backup file copied successfully to R2."
    # Cleans up local backup file
    rm $DUMP_FILE
else
    echo "Error: Failed to copy backup file to R2."
    exit 1
fi
