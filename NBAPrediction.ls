mongodb = require 'mongodb' .MongoClient
async = require 'async'

url = 'mongodb://localhost:27017/nba'
log = console.log

teamMap =
  * celtics: \BOS
    nets: \BKN
    knicks: \NYK
    sixers: \PHI
    raptors: \TOR
    bulls: \CHI
    cavaliers: \CLE
    pistons: \DET
    pacers: \IND
    bucks: \MIL
    hawks: \ATL
    hotnets: \CHA
    heat: \MIA
    magic: \ORL
    wizards: \WAS
    mavs: \DAL
    rockets: \HOU
    grizzlies: \MEM
    pelicans: \NOP
    spurs: \SAS
    nuggets: \DEN
    timerwolves: \MIN
    thunders: \OKC
    blazers: \POR
    jazz: \UTA
    warriors: \GSW
    chippers: \LAC
    lakers: \LAL
    suns: \PHX
    kings: \SAC

getTeamInfo = (teamsCollection, awayTeam, homeTeam) ->
  console.log teamMap[awayTeam]
  console.log teamMap[homeTeam]

loadTeamInfo = (teamsCollection, callback)->
  teamInfo = {}
  teamsCursor = teamsCollection.find!
  err, item <- teamsCursor.nextObject
  # convert the team name to simple Team name
  # e.g. lakers => LAL
  simpleTeamName = teamMap[item.teamName]
  teamInfo[simpleTeamName] = item.data
  console.log item
  callback null


# connect to database
err, db <- mongodb.connect url
games = db.collection('games')
teams = db.collection('teams')

async.waterfall [
  # pass parameter to function 'loadTeaminfo'
  (callback)->
    callback null teams
  , loadTeamInfo
], (err, result)->
  console.log \finish
  db.close!

/*
cursor = games.find!
err, item <- cursor.nextObject
log item
*/
