# Description:
#   Search for tweets on Twitter.
#
# Dependencies:
#   "twit": "1.1.x"
#   "geocoder": "0.2.2"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# Commands:
#   twitterbot show help                                    Show help menu
#   twitterbot show <num> new tweets about <query>          Search all public tweets
#   twitterbot show <num> new tweets by <user>              Get a user's recent tweets
#   twitterbot show <num> random tweets by <user>           Get random tweets by user
#   twitterbot show <num> retweets by <user>                Get retweets by a user
#   twitterbot show <num> tweets about <query> in <location (city, state)>        Get tweets by location
#   twitterbot show <num> most popular tweets about <query> Get most popular tweets
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
    "twitterbot show <num> retweets by <user>\t\tGet retweets by a user",
    "twitterbot show <num> tweets about <query> in <location (city, state)>\t\tGet tweets by location",
    "twitterbot show <num> most popular tweets about <query>\t\tGet most popular tweets"
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
    msg.send "Recent tweets about #{query}"
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
    screen_name: username

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving retweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = []
    i = 0
    j = 1
    msg.send "Retweets from @#{statuses[0].user.screen_name}"
    for status, i in statuses
      if status.text[0..1] == "RT"
        response.push "#{j}. #{status.text}"
        j += 1
      break if (response.length == count)

    return msg.send response.join('\n')

doUserRandom = (msg) ->
  username = msg.match[2]
  return if !username

  twit = getTwit()
  num_tweets = parseInt(msg.match[1])
  searchConfig =
    screen_name: username

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = ''
    randomNums = {}
    i = 0
    count = statuses.length
    msg.send "Random tweets from @#{statuses[0].user.screen_name}"
    for i in [0..num_tweets]
      loop do
        randomNum = Math.floor(Math.random() * count)
        break unless randomNums[randomNum]

      randomNums[randomNum] = true
      response += "#{i + 1}. #{statuses[randomNum].text}"
      response += "\n" if i != num_tweets-1

    return msg.send response

doLocation = (msg, location, city) ->
  twit = getTwit()
  count = msg.match[1]
  query = msg.match[2]
  city = city
  searchConfig =
    q: query
    geocode: location
    count: count
    result_type: 'recent'

  twit.get 'search/tweets', searchConfig, (err, reply) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless reply?.statuses?.length
    statuses = reply.statuses

    response = ''
    i = 0

    msg.send "Recent tweets about #{query} in #{city}"
    for status, i in statuses
      response += "#{i + 1}. **@#{status.user.screen_name}**: #{status.text}"
      response += "\n" if i != count-1

    return msg.send response

doMostPopular = (msg) ->
  twit = getTwit()
  count = msg.match[1]
  query = msg.match[2]
  searchConfig =
    q: query
    count: count
    result_type: 'popular'

  twit.get 'search/tweets', searchConfig, (err, reply) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless reply?.statuses?.length
    statuses = reply.statuses

    response = ''
    i = 0
    msg.send "Most popular tweets about #{query}"
    for status, i in statuses
      response += "#{i + 1}. **@#{status.user.screen_name}**: #{status.text}"
      response += "\n" if i != count-1

    return msg.send response

module.exports = (robot) ->

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

  robot.respond /show (.*) tweets about (.*) in (.*)/i, (msg) ->
    geocoder.geocode msg.match[3], (err, data) ->
      return msg.send "Location error" if err
      loc = data.results[0].geometry.location
      latitude = '' + loc.lat
      longitude = '' + loc.lng
      location = "#{latitude},#{longitude},10mi"
      doLocation(msg, location, msg.match[3])

  robot.respond /show (.*) most popular tweets about (.*)/i, (msg) ->
    doMostPopular(msg)
