# Description:
#   Create and search for tweets on Twitter.
#
# Dependencies:
#   "twit": "1.1.x"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# Commands:
#   hubot twitter <command> <query> - Search Twitter for a query
#
# Author:
#   gkoo
#

Twit = require "twit"

geocoder = require 'geocoder'

config =
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

twit = undefined

getTwit = ->
  unless twit
    twit = new Twit config
  return twit

doHelp = (msg) ->
  commands = [
    "twitterbot show help\t\t\tShow this help menu",
    "twitterbot show <num> new tweets about <query>\t\tSearch all public tweets",
    "twitterbot show <num> new tweets by <user>\t\tGet a user's recent tweets",
    "twitterbot show <num> random tweets by <user>\t\tGet random tweets by user",
    "twitterbot show <num> retweets by <user>\t\tGet retweets by a user"
  ]
  msg.send commands.join('\n')

doSearch = (msg) ->
  query = msg.match[2]
  return if !query

  twit = getTwit()
  count = parseInt(msg.match[1])
  searchConfig =
    q: "#{query}",
    count: count,
    lang: 'en',
    result_type: 'recent'

  twit.get 'search/tweets', searchConfig, (err, reply) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless reply?.statuses?.length

    statuses = reply.statuses
    response = ''
    i = 0
    for status, i in statuses
      response += "#{i + 1}. **@#{status.user.screen_name}**: #{status.text}"
      response += "\n" if i != count-1

    return msg.send response

doUser = (msg) ->
  username = msg.match[2]
  return if !username

  twit = getTwit()
  count = parseInt(msg.match[1])
  searchConfig =
    screen_name: username,
    count: count

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = ''
    i = 0
    msg.send "Recent tweets from @#{statuses[0].user.screen_name}"
    for status, i in statuses
      response += "#{i + 1}. #{status.text}"
      response += "\n" if i != count-1

    return msg.send response

doUserRetweets = (msg) ->
  username = msg.match[2]
  return if !username

  twit = getTwit()
  count = parseInt(msg.match[1])
  searchConfig =
    screen_name: username,
    count: 1000

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving retweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = []
    i = 0
    msg.send "Retweets from @#{statuses[0].user.screen_name}"
    for status, i in statuses
      response.push "#{i + 1}. #{status.text}" if status.retweeted?
      break if (response.length == count)

    return msg.send response.join('\n')

doUserRandom = (msg) ->
  username = msg.match[2]
  return if !username

  twit = getTwit()
  num_tweets = parseInt(msg.match[1])
  count = 100
  searchConfig =
    screen_name: username,
    count: count

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = ''
    i = 0
    msg.send "Random tweets from @#{statuses[0].user.screen_name}"
    for i in [0..num_tweets]
      randomNum = Math.floor(Math.random() * count)
      response += "#{i + 1}. #{statuses[randomNum].text}"
      response += "\n" if i != num_tweets-1

    return msg.send response

doLocation = (msg) ->
  searchString = msg.match[2]
  count = msg.match[1]
  searchConfig = {}
  latitude = ''
  longitude = ''
  response = ''
  geocoder.geocode searchString, (err, data) ->
    msg.send 'geocoder called'
    location = data.results[0].geometry.location
    latitude += location.lat
    longitude += location.lng
    searchConfig =
      query: 'tar heels'
      geocode: "#{latitude},#{longitude},10mi",
      count: count

  twit.get 'search/tweets', searchConfig, (err, reply) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless reply?.statuses?.length

    statuses = reply.statuses
    i = 0
    for status, i in statuses
      response += "#{i + 1}. **@#{status.user.screen_name}**: #{status.text}"
      response += "\n" if i != count-1

    msg.send 'getting here'
    msg.send response

# doTweet = (msg, tweet) ->
#   return if !tweet
#   tweetObj = status: tweet
#   twit = getTwit()
#   twit.post 'statuses/update', tweetObj, (err, reply) ->
#     if err
#       msg.send "Error sending tweet!"
#     else
#       username = reply?.user?.screen_name
#       id = reply.id_str
#       if (username && id)
#         msg.send "https://www.twitter.com/#{username}/status/#{id}"

module.exports = (robot) ->
  robot.respond /show (\S+)\s*(.+)?/i, (msg) ->
    unless config.consumer_key
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_KEY environment variable."
      return
    unless config.consumer_secret
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_SECRET environment variable."
      return
    unless config.access_token
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN environment variable."
      return
    unless config.access_token_secret
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN_SECRET environment variable."
      return

  # robot.respond /tweet\s*(.+)?/i, (msg) ->
  #   doTweet(msg, msg.match[1])
  robot.respond /show help/i, (msg) ->
    doHelp(msg)

  robot.respond /show (.*) new tweets about (.*)/i, (msg) ->
    doSearch(msg)

  robot.respond /show (.*) new tweets by (.*)/i, (msg) ->
    doUser(msg)

  robot.respond /show (.*) random tweets by (.*)/i, (msg) ->
    doUserRandom(msg)

  robot.respond /show (.*) retweets by (.*)/i, (msg) ->
    doUserRetweets(msg)

  robot.respond /show (.*) tweets in (.*)/i, (msg) ->
    doLocation(msg)
