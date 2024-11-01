[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/wYvGYt?referralCode=6bSGmj)

# MySQL Backup to Cloudflare R2

A Docker container that provides automated MySQL database backups to Cloudflare R2 storage using rclone. This solution offers secure, scheduled backups with compression, retention policy management, and multi-database support. Perfect for maintaining reliable database backups in a cloud environment with minimal configuration required.

## Features

- Automated MySQL database backups
- Secure upload to Cloudflare R2 storage
- Configurable backup schedule
- Supports multiple databases
- Compression of backup files
- Retention policy management

# Usage

1. Add the template to your Railway account
2. Set the environment variables
3. Set up recurrent backups with a cron job

## Cron Job

In the template's settings

1. Input a cron schedule to backup as often as you'd like (e.g. `0 0 * * *` for every hour)
2. Set the Restart Policy to 'never'
