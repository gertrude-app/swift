/usr/bin/mkdir -p /home/jared/tmp-backup
/usr/bin/pg_dump --inserts gertrude | /usr/bin/gzip -c > /home/jared/tmp-backup/$(date -u +'%FT%H%MZ').sql.gz
/usr/local/bin/aws s3 cp /home/jared/tmp-backup/*.sql.gz s3://gertrude/db-backups/ --endpoint=https://nyc3.digitaloceanspaces.com --quiet
/usr/bin/rm -rf /home/jared/tmp-backup

