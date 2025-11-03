#!/usr/bin/env bash
# Example: send a Slack notification
MESSAGE=$1
WEBHOOK_URL="https://hooks.slack.com/services/TOKEN_HERE"

if [[ -n "$MESSAGE" ]]; then
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" $WEBHOOK_URL
fi
