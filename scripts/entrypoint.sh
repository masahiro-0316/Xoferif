#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

LOG_DIR="${DJANGO_LOG_DIR:-/app/logs}"
mkdir -p "${LOG_DIR}"

if command -v python >/dev/null 2>&1 && [ -f manage.py ]; then
  python manage.py migrate --noinput 2>&1 | tee "${LOG_DIR}/migrate.log"
  exec python manage.py runserver 0.0.0.0:8000
else
  echo "manage.py が見つからないため、Django サーバーは起動しません。" | tee "${LOG_DIR}/entrypoint.log"
  exec tail -f /dev/null
fi
