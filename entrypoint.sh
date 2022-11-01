#!/bin/bash

set -eux -o pipefail

PARAMETERS="$(mktemp)"
OUTFILE="$(mktemp)"

trap "rm -f $PARAMETERS $OUTFILE" EXIT

cat > "$PARAMETERS" <<EOF
{
    "accessType": "non-exclusive",
    "queueName": "$QUEUE_NAME",
    "permission": "read-only",
    "ingressEnabled": true,
    "egressEnabled": true,
    "maxBindCount": 100,
    "maxMsgSpoolUsage": 1500,
    "owner": "default"
}
EOF

curl -s --location \
  -u "${USERNAME}:${PASSWORD}" \
  --request POST \
  --header 'Content-Type:application/json' \
  --data-binary @"$PARAMETERS" \
  --write-out '%{http_code}' \
  -o "$OUTFILE" \
  "${ENDPOINT}/msgVpns/${VPNNAME}/queues?select=queueName,msgVpnName" | {
    read -r RESPONSE
    echo "response=$RESPONSE" > $GITHUB_OUTPUT
    case "$RESPONSE" in
      200)  echo "HTTP response status code 200: queue successfully created"
        exit 0
        ;; 
      400) echo "HTTP response status code 400: queue already exists"
        exit 1
        ;;
      401) echo "HTTP response status code 401: authorization Failed"
        exit 1
        ;;
      *) echo "HTTP response status code $RESPONSE: unknown"
        exit 1
        ;;
    esac
  }
