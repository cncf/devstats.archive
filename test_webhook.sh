#!/bin/sh
echo "Talk to local test webhook"
curl -H "Content-Type: application/json" -d "@cmd/webhook/example_webhook_payload.dat" -X POST http://cncftest.io:1986/test
echo ""
echo "Done"
