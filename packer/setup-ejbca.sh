#!/bin/bash
set -euxo pipefail

: "${TLS_MODE:?TLS_MODE not set}"
: "${HOSTNAME:?HOSTNAME not set}"

sed "s/{{TLS_MODE}}/${TLS_MODE}/g; s/{{HOSTNAME}}/${HOSTNAME}/g" \
  /tmp/ejbca.service | sudo tee /etc/systemd/system/ejbca.service > /dev/null
