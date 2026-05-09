# backupJob

Alpine-based container image with `s3cmd` for backing up and restoring eevee botModule PVCs to S3-compatible object storage.

## What It Does

- **Backup** — tars the PVC contents and uploads to S3 with a UUID-based key
- **Restore** — downloads a backup from S3 and extracts it into the PVC

Designed to run as a K8s Job container, driven by the eevee operator.

## Usage

The operator sets the container command to select which script runs:

```yaml
# Backup (CronJob)
command: ["/usr/local/bin/backup.sh"]

# Restore (one-shot Job)
command: ["/usr/local/bin/restore.sh"]
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `S3_ENDPOINT` | yes | S3-compatible endpoint URL |
| `S3_BUCKET` | yes | Bucket name |
| `S3_PREFIX` | no | Key prefix within the bucket |
| `S3_ACCESS_ID` | yes | Access key ID (from Secret) |
| `S3_SECRET_KEY` | yes | Secret access key (from Secret) |
| `S3_PATH_STYLE` | no | Set `true` for path-style addressing (MinIO, etc.) |
| `BACKUP_NAMESPACE` | yes (backup) | Bot instance namespace |
| `BACKUP_MODULE` | yes (backup) | Module name |
| `BACKUP_PVC_PATH` | no | PVC mount path (default: `/data`) |
| `RESTORE_NAMESPACE` | yes (restore) | Bot instance namespace |
| `RESTORE_MODULE` | yes (restore) | Module name |
| `RESTORE_BACKUP_ID` | yes (restore) | UUID of the backup to restore |

## S3 Key Format

```
<prefix>/<namespace>/<moduleName>/<uuid>.tar.gz
```

## License

[CC BY-NC-SA 4.0](LICENSE)
