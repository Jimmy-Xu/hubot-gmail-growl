# Description:
#   Get new mail from GMail, then notify via growl
#
# Configuration:
#   HUNOT_GMAIL_USERNAME
#   HUBOT_GMAIL_PASSWORD
#   HUBOT_GMAIL_LABEL
#   HUBOT_GMAIL_CHECK_INTERVAL
#   HUBOT_GNTP_SERVER
#   HUBOT_GNTP_PASSWORD
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

_ = require 'lodash'
  
module.exports = (robot) ->

###################################################
# func
###################################################
  run_gntp_cmd = (message, cb) ->
    appName = "hubot-gmail-growl"
    defaultPort = "23053"
    if robot.adapterName is "slack"
      title = "From Slack[\##{roomName} #{senderName}]"
    else
      title = "From #{robot.adapterName}"

    server = process.env.HUBOT_GNTP_SERVER
    if server? and server isnt ""
      if (server.split ":").length is 1
        server = server + ":" + defaultPort
      else if (server.split ":").length > 2
        console.log "'#{server}' is invalid server, skip execute gntp-send"
        return
    else
      console.log "no gntp server specified, skip execute gntp-send"
      return

    # prepare args
    args = ["-s", server, "-p", process.env.HUBOT_GNTP_PASSWORD, "-a", appName, title, message]
    console.debug "[run_gntp_cmd] spawn: gntp-send ", args
    # exec gntp-send
    spawn = require("child_process").spawn
    child = spawn("gntp-send", args)
    result = []
    child.stdout.on "data", (buffer) -> result.push buffer.toString()
    child.stderr.on "data", (buffer) -> result.push buffer.toString()
    child.stdout.on "end", -> cb result


###################################################
# main
###################################################
  timer = 0
  interval = parseInt(process.env.HUBOT_GMAIL_CHECK_INTERVAL || 1)
  label = process.env.HUBOT_GMAIL_LABEL || "Inbox"
  client = false

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
    robot.logger.info "Initializing IMAP client..."
    _client = inbox.createConnection false, "imap.gmail.com", {
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
        setTimer interval, msg
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
        msg.send "From: #{sender.name} <#{sender.address}>\n Subject: #{mail.subject}\n"
        run_gntp_cmd mailDetail, (text) ->
          console.log "gntp result:", text
      ), (() ->
        robot.logger.info "Max UID: #{client.lastfetch}"
        setTimer interval, msg
      )

  doFetch = (callback, onFinish) ->
    robot.logger.info "Check it!"
    client.listMessages -10, (e, messages) ->
      maxUID = _.max(_.map messages, (m) -> m.UID)
      if e
        callback e
      else if maxUID <= client.lastfetch
        callback(new Error "No new mail")
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
