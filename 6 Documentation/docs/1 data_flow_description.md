Users connect to the OpenVPN server using the OpenVPN client on their own devices (for example, from home or the office).

After establishing the VPN connection, they open a browser and navigate to Grafana at https://{ip}:3000.

Administrators use SSH from the management server to access the AWS instances.

Prometheus automatically scrapes metrics from the exporters without any manual intervention from users.

Every day at 8 a.m., the management server performs a backup of system files and folders, adding the current date to the archive name, and then uploads it to the MinIO object-storage server (this is handled by a dedicated cron job that runs the backup script at the scheduled time).