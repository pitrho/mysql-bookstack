Bookstack Backup Recovery

Connect to the host where the 'bookstack-db-backup' container service is running.

S3 Bucket: pitrho-backups/internal_documentation

docker exec -i [container id] /backup_recovery.sh [s3 file to restore from]

docker exec -i [container id] /backup_recovery.sh public_uploads_12162016_195747.tar.gz

# restore from the last backup made.
docker exec -i [container id] /backup_recovery.sh



*Anytime the documentation stack is started it should be loaded from a backup.



#XXX: Combine the db and the data backup into one backup?

Restart the bookstack-db-backup container for restoring the database.

Stop the bookstack-lb container to prevent database updates during the restore.

#FIXME: Change the entrypoint for the backup.

/var/www/BookStack/public/uploads

#TODO: Keep the uid:gid and perms on the file backups.
Remove any data in the mounted volume.
Extract the data into the volume directory.
Ensure the permissions and uid:gid are correct:

chown -R www-data: <volume dir> && chmod -R 755 <volume dir>

#TODO: Does the cache need to be cleared?
php artisan cache:clear
php artisan view:clear


1) Restore from the container host.

2) Restore using the bookstack-db-backup container.


