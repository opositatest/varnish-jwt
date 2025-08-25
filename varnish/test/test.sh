#!/bin/bash

set -x

TOKEN='aaaeyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJlIjoiOkJERTEwMDAzNTE6IiwiZXhwIjoyMDM0NDMyMzYyLCJzdWIiOiJodHRwX3Rlc3QifQ.rsJrHXD0LIH-rt1_kicGb6xAJK0-zLAQ-kRJfAYQNivOcIrpqIugjmmoDm2f-tGjcu5n7PrcYm4HHIN3X_mLZw'

varnishd -f /etc/varnish/default.vcl &
export DEBIAN_FRONTEND=noninteractive DEBCONF_NOWARNINGS=yes
apt update > /dev/null
apt install --no-install-recommends -y jq > /dev/null

echo Test bad token. Error is OK
result="$(curl -s -H 'Authorization: Bearer '$TOKEN'' -X GET localhost -H  'accept: application/json')"
jq -e . >/dev/null <<<"$result"
