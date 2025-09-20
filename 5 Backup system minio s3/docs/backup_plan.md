Backup Plan

**1\. Purpose**

Automatic creation of system backups, excluding temporary directories.

Storage of backups:

\- Locally — in \`/var/backups\`;

\- Remotely — in MinIO (S3-compatible object storage).

Execution monitoring via log files and metrics in Prometheus/Grafana.

**2\. Architecture**

Bash script — handles archiving and uploading.

Cron — runs the script on a schedule.

MinIO — backup storage.

Logs:

\- \`/var/log/backup_minio.log\` — for local auditing;

\- Prometheus metrics (e.g., \`backup_success\`, \`backup_failure\`).

Grafana — visualization and alerts based on backup status.

**3\. Sequence of Actions**

1\. Create a timestamped archive (e.g., \`backup-2025-07-08.tar.gz\`).

2\. Save the archive to \`/var/backups\`.

3\. Upload the archive to MinIO.

4\. Write information to the log file \`/var/log/backup_minio.log\`.

5\. Send backup results to Prometheus.

6\. Grafana displays status and triggers alerts in case of errors.

**4\. Errors and Actions**

| Error | Action |
| --- | --- |
| Archive creation failed | Retry, log, send notification. |
| Insufficient disk space | Delete old archives, log, send notification. |
| Upload to MinIO failed | Retry multiple times, keep a local copy. |
| Corrupted archive | Mark, log, investigate. |
| Expired MinIO keys/access | Stop backup, log, notify, rotate keys. |

**5\. Artifact Storage**

\- Archives: \`/var/backups/backup-&lt;date&gt;.tar.gz\`

\- MinIO: stored under the same name.

\- Logs: \`/var/log/backup_minio.log\`

\- Monitoring: via Prometheus metrics and Grafana dashboards.

\- Scheduler: \`cron\`, e.g., daily at 02:00.