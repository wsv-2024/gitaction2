###############################################################################
# GitHub Actions Runner (Docker-fähig) – Ubuntu 22.04 – Runner v2.324.0
###############################################################################

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ───────────────────────────────────────────────────────────────
# 1) Basis-Pakete (inkl. docker.io, gosu **und git-lfs**)
# ───────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg2 tar git jq \
        libicu70 libkrb5-3 libssl3 libstdc++6 \
        docker.io gosu git-lfs && \
    git lfs install --system && \        # ← LFS-Filter global registrieren
    rm -rf /var/lib/apt/lists/*

# ───────────────────────────────────────────────────────────────
# 2) Benutzer & Gruppe „docker“
# ───────────────────────────────────────────────────────────────
RUN groupadd -f docker && \
    useradd --create-home --shell /bin/bash --gid docker runner

# ───────────────────────────────────────────────────────────────
# 3) Verzeichnis für den GitHub-Runner
# ───────────────────────────────────────────────────────────────
RUN mkdir -p /home/runner/actions-runner
WORKDIR /home/runner/actions-runner

# ───────────────────────────────────────────────────────────────
# 4) Runner-Binary herunterladen, verifizieren, entpacken
# ───────────────────────────────────────────────────────────────
ARG RUNNER_VERSION=2.324.0
ARG RUNNER_SHA256="e8e24a3477da17040b4d6fa6d34c6ecb9a2879e800aa532518ec21e49e21d7b4"

RUN curl -sSL -o runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
    echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c - && \
    tar -xzf runner.tar.gz && rm runner.tar.gz

# ───────────────────────────────────────────────────────────────
# 5) Feste Runner-Parameter (bei Bedarf anpassen)
# ───────────────────────────────────────────────────────────────
ENV GH_RUNNER_URL="https://github.com/wsv-2024/yolo-tracking-multi-image-linux" \
    GH_RUNNER_NAME="yolo-runner-2" \
    GH_RUNNER_WORKDIR="_work" \
    GH_RUNNER_LABELS="self-hosted,docker,linux"

# ───────────────────────────────────────────────────────────────
# 6) Entrypoint kopieren
# ───────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
