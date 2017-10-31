# Description:
#   Get new mail from GMail, then notify via growl
#
# Configuration:
#   HUBOT_GMAIL_USERNAME
#   HUBOT_GMAIL_PASSWORD
#   HUBOT_GMAIL_LABEL
#   HUBOT_GMAIL_CHECK_INTERVAL
#   HUBOT_GNTP_SERVER
#   HUBOT_GNTP_PASSWORD
#   HUBOT_IMAP_PROXY_SERVER
#   HUBOT_IMAP_PROXY_PORT
#
# Commands:
#   hubot gmail-growl start - Start the gmail checker via IMAP
#   hubot gmail-growl change <mins> - Change the interval of gmail checker
#   hubot gmail-growl stop - Stop the gmail update
#
# Author:
#   Jimmy Xu / (xjimmyshcn@gmail.com)
#
# See Also:
#   reference: https://github.com/udzura/hubot-gmail-fetcher

inbox        = require 'inbox'
{MailParser} = require 'mailparser'
nodeGrowl    = require 'node-growl'

_ = require 'lodash'

module.exports = (robot) ->

###################################################
# main
###################################################
  timer = 0
  interval = parseInt(process.env.HUBOT_GMAIL_CHECK_INTERVAL || 1)
  label = process.env.HUBOT_GMAIL_LABEL || "Inbox"
  client = false
  gntpOpts =
    server: process.env.HUBOT_GNTP_SERVER
    password: process.env.HUBOT_GNTP_PASSWORD
    appname: "hubot-gmail-growl"

  robot.respond /gmail-growl start/i, (msg) ->
    if not client
      client = initClient(msg)
      if client
        msg.send "Started the GMail fetch"
    else
      msg.send "Its already running!"

  robot.respond /gmail-growl stop/i, (msg) ->
    if client
      client.close()
      client = false
      clearTimeout timer
      msg.send "Stopped the GMail fetch"

  robot.respond /gmail-growl change ([1-9][0-9]*)/i, (msg) ->
    clearTimeout timer
    interval = parseInt msg.match[1]
    setTimer interval, msg
    msg.send "Changed the GMail fetch interval"

  initClient = (msg) ->
    gmail_server =  "imap.gmail.com"
    gmail_port = false
    if process.env.HUBOT_IMAP_PROXY_SERVER and process.env.HUBOT_IMAP_PROXY_PORT
      gmail_server = process.env.HUBOT_IMAP_PROXY_SERVER
      gmail_port = process.env.HUBOT_IMAP_PROXY_PORT
    robot.logger.info "Initializing IMAP client..."
    _client = inbox.createConnection gmail_port, gmail_server, {
      secureConnection: true
      auth:
        user: process.env.HUBOT_GMAIL_USERNAME
        pass: process.env.HUBOT_GMAIL_PASSWORD
    }
    _client.lastfetch = 0
    _client.connect()
    _client.on 'connect', () ->
      _client.openMailbox label, (e, info) ->
        if e
          msg.send e
          return false
        robot.logger.info("Message count in #{label}: " + info.count)
        setTimer 0, msg
    return _client

  setTimer = (_interval, msg) ->
    timer = setTimeout doFetch, _interval * 60 * 1000, ((e, mail) ->
      if e
        robot.logger.info e
      else
        robot.logger.info "Get mail: ", mail.subject
        mailDetail = ""
        sender = mail.from[0]
        mailDetail += "From: #{sender.name} <#{sender.address}>\n"
        mailDetail += "Subject: #{mail.subject}\n"
        if mail.text
          mailDetail += "\n"
          mailDetail += mail.text
        msgTitle = "From: #{sender.name} <#{sender.address}>"
        msgContent = "Subject: #{mail.subject}"
        msg.send "#{msgTitle}\n#{msgContent}"
        # notify via gntp-send
        console.debug "title:", msgTitle, " message:", msgContent, " gntpOpts:", gntpOpts
        nodeGrowl msgTitle, msgContent, gntpOpts, (text) ->
          if text isnt null
            console.log ">gntp-send failed:", text
          else
            console.log ">gntp-send OK"
    ), (() ->
      robot.logger.info "Max UID: #{client.lastfetch}"
      setTimer interval, msg
    )

  doFetch = (callback, onFinish) ->
    batchN = 0
    if client.lastfetch is 0
      batchN = 1
      robot.logger.info "First time check, get latest #{batchN} email"
    else
      batchN = 10
      robot.logger.info "Check it!(get latest #{batchN}) emails"
    client.listMessages -batchN, (e, messages) ->
      maxUID = _.max(_.map messages, (m) -> m.UID)
      if e
        callback e
      else if maxUID <= client.lastfetch
        callback("No new mail")
      else
        for message in messages
          if client.lastfetch < message.UID
            stream = client.createMessageStream(message.UID)
            mailparser = new MailParser()
            mailparser.on 'end', (mail) ->
              callback(null, mail)
            stream.pipe(mailparser)
        client.lastfetch = maxUID
      onFinish()
