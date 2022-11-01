#!/bin/bash

set -eux -o pipefail

PARAMETERS="$(mktemp)"
OUTFILE="$(mktemp)"

trap "rm -f $PARAMETERS $OUTFILE" EXIT

cat > "$PARAMETERS" <<EOF
{
    "accessType": "non-exclusive",
    "queueName": "$QUEUENAME",
    "permission": "read-only",
    "ingressEnabled": true,
    "egressEnabled": true,
    "maxBindCount": 100,
    "maxMsgSpoolUsage": 1500,
    "owner": "default"
}
EOF

curl --verbose --location \
  -u "${USERNAME}:${PASSWORD}" \
  --header 'content-type:application/json' \
  --data-binary @"$PARAMETERS" \
  --write-out '%{http_code}' \
  -o "$OUTFILE" \
  "${ENDPOINT}/msgVpns/${VPNNAME}/queues?select=queueName,msgVpnName" | {
    read -r RESPONSE
    # echo "response=$RESPONSE" > $GITHUB_OUTPUT
    case "$RESPONSE" in
      200)  echo "HTTP response status code 200: queue successfully created"
        exit 0
        ;; 
      400) echo "HTTP response status code 400: queue already exists"
        ;;
      401) echo "HTTP response status code 401: authorization Failed"
        ;;
      *) echo "HTTP response status code $RESPONSE: unknown"
        ;;
    esac
    exit 1
  }
