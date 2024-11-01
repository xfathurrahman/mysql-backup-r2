# syntax=docker/dockerfile:1

FROM rclone/rclone:1.68.1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV MYSQL_HOST=""
ENV MYSQL_PORT=""
ENV MYSQL_USER=""
ENV MYSQL_PASSWORD=""
ENV MYSQL_DB_NAME=""
ENV R2_ACCESS_KEY_ID=""
ENV R2_SECRET_ACCESS_KEY=""
ENV R2_BUCKET=""
ENV R2_S3_ENDPOINT=""

CMD ["/entrypoint.sh"]