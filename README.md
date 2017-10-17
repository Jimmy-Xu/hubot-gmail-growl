hubot-gmail-growl
==============================

[Hubot](http://hubot.github.com/) script to check Gmail and notify via growl.


#### external-scripts.json

    ["hubot-gmail-growl"]

Run `npm install` to install hubot-gmail-growl and dependencies.


## Environmental variables

```
//for gmail
HUBOT_GMAIL_USER           # - email address
HUBOT_GMAIL_PASSWORD       # - email password
HUBOT_GMAIL_LABEL          # - Gmail label name
HUBOT_GMAIL_CHECK_INTERVAL # default fetch interval(mins)

//for gntp
HUBOT_GNTP_SERVER    # - gntp server ip address
HUBOT_GNTP_PASSWORD  # - gntp password
```

## Usage

Use `hubot help` or check the gmail-growl.coffee file to get the full list of options with short descriptions.

```
hubot gmail-growl change <mins> - Change the interval of gmail updates
hubot gmail-growl start - Start the gmail update via IMAP
hubot gmail-growl stop - Stop the gmail update
```
