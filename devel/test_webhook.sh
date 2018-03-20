#!/bin/bash
echo "Talk to local test webhook"
curl -H "Content-Type: application/json" -d "@cmd/webhook/example_webhook_payload_deploy.dat" -X POST http://127.0.0.1:1986/test
#curl -H "Content-Type: application/json" -d "@cmd/webhook/example_webhook_payload_no_deploy.dat" -X POST http://127.0.0.1:1986/test
echo ""
echo "Done"
