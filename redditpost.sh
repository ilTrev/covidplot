#!/bin/bash

TITLE="$1"
TEXT="$2"
USER=$(cat reddit.credential | grep user | cut -f2 -d",")
PASSWORD=$(cat reddit.credential | grep pass | cut -f2 -d",")
APP=$(cat reddit.credential | grep "^app" | cut -f2 -d",")
USERAGENT='InstantCOVID by iltrev'

TOKEN=$(jq -r ".access_token" <<<$(curl -X POST -A "$USERAGENT" -d "grant_type=password&username=$USER&password=$PASSWORD" --user "$APP" https://www.reddit.com/api/v1/access_token))

curl -X POST --header "Authorization: bearer $TOKEN"  --header "Content-Type: application/x-www-form-urlencoded" --header "User-Agent: $USERAGENT" --data "title=$TITLE&kind=self&text=$TEXT&sr=test&resubmit=true&send_replies=true&api_type=json" 'https://oauth.reddit.com/api/submit.json' 
