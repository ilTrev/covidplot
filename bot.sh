#!/bin/bash

TELEGRAM_BOT_TOKEN="1335167290:AAH4x0nTi0BagNxx5e8272N-fdiSqKuhjh4"

curl -X POST -H 'Content-Type: application/json' -d '{ "chat_id": "@iltrevcovid", "text": "This is a test from curl" }' https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage

	# "disable_notification": true}' \
