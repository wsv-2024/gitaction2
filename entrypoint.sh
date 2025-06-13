#!/usr/bin/env bash
set -euo pipefail

SOCK=/var/run/docker.sock
RUNNER_DIR=/home/runner/actions-runner

###############################################################################
# 0) PAT prüfen
###############################################################################
: "${GH_PAT:?Setze GH_PAT als langfristigen Personal-Access-Token!}"

###############################################################################
# 1) Docker-Socket-GID übernehmen
###############################################################################
if [[ -S $SOCK ]]; then
  GID=$(stat -c '%g' "$SOCK")
  if ! getent group "$GID" >/dev/null; then
    groupadd -g "$GID" docker-host
  fi
  usermod -aG "$GID" runner
fi

###############################################################################
# 2) Registrierungs-Token holen (nur, wenn .runner noch fehlt)
###############################################################################
cd "$RUNNER_DIR"

if [[ ! -f .runner ]]; then
  echo ">> Hole frischen Registrierungs-Token …"

  OWNER_REPO=${GH_RUNNER_URL#https://github.com/}       # wsv-2024/yolo-tracking-image-linux
  REG_TOKEN=$(curl -s -XPOST \
      -H "Authorization: Bearer $GH_PAT" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$OWNER_REPO/actions/runners/registration-token" \
      | jq -r .token)

  echo ">> Registriere Runner '${GH_RUNNER_NAME}' …"
  gosu runner ./config.sh --unattended \
         --url    "$GH_RUNNER_URL" \
         --token  "$REG_TOKEN" \
         --name   "$GH_RUNNER_NAME" \
         --work   "$GH_RUNNER_WORKDIR" \
         --labels "$GH_RUNNER_LABELS" --replace
else
  echo ">> .runner vorhanden – Registrierung übersprungen."
fi

###############################################################################
# 3) Runner starten
###############################################################################
echo ">> Starte GitHub Runner"
exec gosu runner ./run.sh
