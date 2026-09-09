#!/usr/bin/env bash
set -euo pipefail

esito=0

if git ls-files --error-unmatch config/impostazioni.txt 2>/dev/null; then
  echo "::error::config/impostazioni.txt e ancora tracciato da git"
  esito=1
fi

if git grep -nIE '(FTP_PASSWORD=.+|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36})' \
     -- ':!*.esempio.txt' ':!ci/nessun-segreto.sh'; then
  echo "::error::trovato un possibile segreto nei file versionati"
  esito=1
fi

if [ "$esito" -eq 0 ]; then echo "OK: nessun segreto trovato"; fi
exit "$esito"
