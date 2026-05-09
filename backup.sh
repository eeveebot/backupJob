#!/usr/bin/env bash
set -euo pipefail

# --- Required env vars (injected by operator) ---
S3_ENDPOINT="${S3_ENDPOINT:?S3_ENDPOINT is required}"
S3_BUCKET="${S3_BUCKET:?S3_BUCKET is required}"
S3_PREFIX="${S3_PREFIX:-}"
S3_ACCESS_ID="${S3_ACCESS_ID:?S3_ACCESS_ID is required}"
S3_SECRET_KEY="${S3_SECRET_KEY:?S3_SECRET_KEY is required}"
S3_PATH_STYLE="${S3_PATH_STYLE:-false}"
BACKUP_NAMESPACE="${BACKUP_NAMESPACE:?BACKUP_NAMESPACE is required}"
BACKUP_MODULE="${BACKUP_MODULE:?BACKUP_MODULE is required}"
BACKUP_PVC_PATH="${BACKUP_PVC_PATH:-/data}"

# --- Generate backup UUID ---
BACKUP_UUID="$(uuidgen)"
S3_KEY="${S3_PREFIX}${BACKUP_NAMESPACE}/${BACKUP_MODULE}/${BACKUP_UUID}.tar.gz"

# --- Write s3cmd config ---
HOST_BASE="${S3_ENDPOINT#*://}"
cat > /tmp/.s3cfg <<EOF
[default]
access_key = ${S3_ACCESS_ID}
secret_key = ${S3_SECRET_KEY}
host_base = ${HOST_BASE}
use_https = True
EOF

if [ "${S3_PATH_STYLE}" = "true" ]; then
  echo "host_bucket = ${HOST_BASE}" >> /tmp/.s3cfg
else
  echo "host_bucket = %(bucket)s.${HOST_BASE}" >> /tmp/.s3cfg
fi

# --- Create archive ---
TMPFILE="$(mktemp /tmp/backup-XXXXXX.tar.gz)"
trap 'rm -f "${TMPFILE}"' EXIT

tar -czf "${TMPFILE}" -C "${BACKUP_PVC_PATH}" .

# --- Upload ---
echo "Uploading backup ${BACKUP_UUID} to s3://${S3_BUCKET}/${S3_KEY}"
s3cmd -c /tmp/.s3cfg put "${TMPFILE}" "s3://${S3_BUCKET}/${S3_KEY}"

echo "Backup complete: ${BACKUP_UUID}"
