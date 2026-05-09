#!/usr/bin/env bash
set -euo pipefail

# --- Required env vars (injected by operator) ---
S3_ENDPOINT="${S3_ENDPOINT:?S3_ENDPOINT is required}"
S3_BUCKET="${S3_BUCKET:?S3_BUCKET is required}"
S3_PREFIX="${S3_PREFIX:-}"
S3_ACCESS_ID="${S3_ACCESS_ID:?S3_ACCESS_ID is required}"
S3_SECRET_KEY="${S3_SECRET_KEY:?S3_SECRET_KEY is required}"
S3_PATH_STYLE="${S3_PATH_STYLE:-false}"
RESTORE_NAMESPACE="${RESTORE_NAMESPACE:?RESTORE_NAMESPACE is required}"
RESTORE_MODULE="${RESTORE_MODULE:?RESTORE_MODULE is required}"
RESTORE_BACKUP_ID="${RESTORE_BACKUP_ID:?RESTORE_BACKUP_ID is required}"
BACKUP_PVC_PATH="${BACKUP_PVC_PATH:-/data}"

S3_KEY="${S3_PREFIX}${RESTORE_NAMESPACE}/${RESTORE_MODULE}/${RESTORE_BACKUP_ID}.tar.gz"

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

# --- Download ---
TMPFILE="$(mktemp /tmp/restore-XXXXXX.tar.gz)"
trap 'rm -f "${TMPFILE}"' EXIT

echo "Downloading backup ${RESTORE_BACKUP_ID} from s3://${S3_BUCKET}/${S3_KEY}"
s3cmd -c /tmp/.s3cfg get "s3://${S3_BUCKET}/${S3_KEY}" "${TMPFILE}"

# --- Extract ---
tar -xzf "${TMPFILE}" -C "${BACKUP_PVC_PATH}"

echo "Restore complete: ${RESTORE_BACKUP_ID}"
