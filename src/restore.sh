#!/usr/bin/env bash
set -euo pipefail

# --- Required env vars (injected by operator) ---
S3_ENDPOINT="${S3_ENDPOINT:?S3_ENDPOINT is required}"
S3_BUCKET="${S3_BUCKET:?S3_BUCKET is required}"
S3_PREFIX="${S3_PREFIX:-}"
S3_ACCESS_ID="${S3_ACCESS_ID:?S3_ACCESS_ID is required}"
S3_SECRET_KEY="${S3_SECRET_KEY:?S3_SECRET_KEY is required}"
S3_PATH_STYLE="${S3_PATH_STYLE:-false}"
S3_SIGNATURE_V2="${S3_SIGNATURE_V2:-false}"
RESTORE_NAMESPACE="${RESTORE_NAMESPACE:?RESTORE_NAMESPACE is required}"
RESTORE_MODULE="${RESTORE_MODULE:?RESTORE_MODULE is required}"
RESTORE_BACKUP_ID="${RESTORE_BACKUP_ID:?RESTORE_BACKUP_ID is required}"
BACKUP_PVC_PATH="${BACKUP_PVC_PATH:-/data}"
RESTORE_CLEAN="${RESTORE_CLEAN:-false}"

S3_KEY="${S3_PREFIX}${RESTORE_NAMESPACE}/${RESTORE_MODULE}/${RESTORE_BACKUP_ID}.tar.gz"

# --- Write s3cmd config ---
HOST_BASE="${S3_ENDPOINT#*://}"
cat > /tmp/.s3cfg <<EOF
[default]
access_key = ${S3_ACCESS_ID}
secret_key = ${S3_SECRET_KEY}
host_base = ${HOST_BASE}
use_https = $(if [[ "${S3_ENDPOINT}" == https://* ]]; then echo True; else echo False; fi)
signature_v2 = $(if [[ "${S3_SIGNATURE_V2}" == "true" ]]; then echo True; else echo False; fi)
EOF
chmod 600 /tmp/.s3cfg

if [ "${S3_PATH_STYLE}" = "true" ]; then
  echo "host_bucket = ${HOST_BASE}" >> /tmp/.s3cfg
else
  echo "host_bucket = %(bucket)s.${HOST_BASE}" >> /tmp/.s3cfg
fi

# --- Download ---
TMPFILE="$(mktemp /tmp/restore-XXXXXX.tar.gz)"
trap 'rm -f "${TMPFILE}"' EXIT

echo "Downloading backup ${RESTORE_BACKUP_ID} from s3://${S3_BUCKET}/${S3_KEY}"
if ! s3cmd -c /tmp/.s3cfg get "s3://${S3_BUCKET}/${S3_KEY}" "${TMPFILE}"; then
  echo "ERROR: Download failed for backup ${RESTORE_BACKUP_ID}" >&2
  exit 1
fi

# --- Optionally clean the target directory before extracting ---
if [ "${RESTORE_CLEAN}" = "true" ]; then
  echo "Cleaning ${BACKUP_PVC_PATH} before restore (RESTORE_CLEAN=true)"
  rm -rf "${BACKUP_PVC_PATH:?}"/*
fi

# --- Extract ---
tar -xzf "${TMPFILE}" -C "${BACKUP_PVC_PATH}"

echo "Restore complete: ${RESTORE_BACKUP_ID}"
