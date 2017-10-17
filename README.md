hubot-gmail-growl
==============================

[Hubot](http://hubot.github.com/) script to check Gmail and notify via growl.


# Dependency

- inbox
- mailparser
- node-growl


# external-scripts.json

    ["hubot-gmail-growl"]

Run `npm install` to install hubot-gmail-growl and dependencies.


# Environmental variables

```
//for gmail
HUBOT_GMAIL_USERNAME       # - email address
HUBOT_GMAIL_PASSWORD       # - email password
HUBOT_GMAIL_LABEL          # - Gmail label name
HUBOT_GMAIL_CHECK_INTERVAL # default fetch interval(mins)

//for gntp
HUBOT_GNTP_SERVER    # - gntp server ip address
HUBOT_GNTP_PASSWORD  # - gntp password
```

# Usage

Use `hubot help` or check the gmail-growl.coffee file to get the full list of options with short descriptions.

```
hubot gmail-growl change <mins> - Change the interval of gmail updates
hubot gmail-growl start - Start the gmail update via IMAP
hubot gmail-growl stop - Stop the gmail update
```

# Run with docker

REF: https://github.com/jjethwa/hubot-slack


## start by manual

```
export EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl"
export HUBOT_GNTP_SERVER="192.168.1.23:23053"
export HUBOT_GNTP_PASSWORD="xxxxxx"
export HUBOT_GMAIL_USERNAME="xxx@hyper.sh"
export HUBOT_GMAIL_PASSWORD="xxxxx"
export HUBOT_GMAIL_LABEL="xxx"
export HUBOT_GMAIL_CHECK_INTERVAL="5"

// add plugin hubot-gmail-growl
// for basic auth, go to https://myaccount.google.com/security?pli=1#connectedapps, set "Allow less secure app" to "ON"
$ docker run --name "hubot-growl" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
-e HUBOT_GNTP_SERVER="${HUBOT_GNTP_SERVER}" -e HUBOT_GNTP_PASSWORD="${HUBOT_GNTP_PASSWORD}" \
-e HUBOT_GMAIL_USERNAME="$HUBOT_GMAIL_USERNAME" -e HUBOT_GMAIL_PASSWORD="$HUBOT_GMAIL_PASSWORD" \
-e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL="$HUBOT_GMAIL_CHECK_INTERVAL" \
-it --rm \
jordan/hubot-slack:latest /bin/bash

// run the following command line in container
//install external module
node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))")

//start hubot
HUBOT_LOG_LEVEL=debug  bin/hubot -n $HUBOT_NAME
```

## start as daemon

```
$ docker run --name "hubot-growl" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
-e HUBOT_GNTP_SERVER="${HUBOT_GNTP_SERVER}" -e HUBOT_GNTP_PASSWORD="${HUBOT_GNTP_PASSWORD}" \
-e HUBOT_GMAIL_USERNAME="$HUBOT_GMAIL_USERNAME" -e HUBOT_GMAIL_PASSWORD="$HUBOT_GMAIL_PASSWORD" \
-e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL="$HUBOT_GMAIL_CHECK_INTERVAL" \
-d \
jordan/hubot-slack:latest
```

