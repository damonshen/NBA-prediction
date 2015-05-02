mongodb = require 'mongodb' .MongoClient
async = require 'async'
_ = require 'underscore'
# framework of neural network
synaptic = require 'synaptic'
Architect = synaptic.Architect
Trainer = synaptic.Trainer

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
    hornets: \CHA
    heat: \MIA
    magic: \ORL
    wizards: \WAS
    mavs: \DAL
    rockets: \HOU
    grizzlies: \MEM
    pelicans: \NOP
    spurs: \SAS
    nuggets: \DEN
    timberwolves: \MIN
    thunder: \OKC
    blazers: \POR
    jazz: \UTA
    warriors: \GSW
    clippers: \LAC
    lakers: \LAL
    suns: \PHX
    kings: \SAC

_teamsInfo = null

loadTeamInfo = (db, callback)->
  allTeamsInfo = {}
  # iterate all element from response of database
  teamsCollection = db.collection('teams')
  do
    err, teams<- teamsCollection.find!.toArray

    for team in teams
      # convert the team name to simple Team name
      # e.g. lakers => LAL
      simpleTeamName = teamMap[team.teamName]
      # add team information into a list
      allTeamsInfo[simpleTeamName] = team.data
    #console.log allTeamsInfo

    _teamsInfo := allTeamsInfo
    callback null, db, allTeamsInfo

# load the game information and add the team information
# to generate the input data for neural network
loadGameInfo = (db, teamsInfo, callback) ->
  # the data of neural network
  dataSet = []
  gameCollection = db.collection('games')
  err, games <- gameCollection.find!.toArray
  for game in games
    gameInput = []
    #console.log game.awayTeam.name, ' vs ', game.homeTeam.name
    awayName = game.awayTeam.name
    homeName = game.homeTeam.name
    if awayName is \DAL or homeName is \DAL
      continue
    # get team information
    awayTeamInfo =  teamsInfo[awayName]['Road']
    homeTeamInfo =  teamsInfo[homeName]['Home']
    inputData = getInputData awayName, homeName
    outputData = getOutputData game
    data = generateData inputData, outputData
    dataSet.push data
  callback null, dataSet

generateData = (inputArray, outputArray) ->
  return data =
    * input: inputArray
      output: outputArray

getInputData = (awayName, homeName) ->
  # get the teams information
  awayTeamInfo =  _teamsInfo[awayName]['Road']
  homeTeamInfo =  _teamsInfo[homeName]['Home']
  # merge the object into array and remove the '%'
  awayTeamValuesArray = getValueFromArray awayTeamInfo
  homeTeamValuesArray = getValueFromArray homeTeamInfo

  # concat two array
  inputArray = awayTeamValuesArray.concat homeTeamValuesArray
  # normalize the input data
  inputArray = do
    numStr <- _.map inputArray
    num = parseFloat numStr
    num /= 100
  return inputArray

getOutputData = (gamesInfo) ->
  # get the scores of the games
  away = gamesInfo.awayTeam.score
  home = gamesInfo.homeTeam.score
  output = []
  # get the scores of first quarter and final
  awayFirst = away[0]
  awayFinal = away[away.length-1]
  homeFirst = home[0]
  homeFinal = home[home.length-1]

  #output.push awayFirst
  output.push awayFinal
  #output.push homeFirst
  output.push homeFinal
  # normalize the data
  output = do
    numStr <- _.map output
    num = parseFloat numStr
    num /= 200
  return output

# merge the values of Objects to an array
getValueFromArray = (array) ->
  valuesArray = []
  for k,v of array
    if k is not \SPLIT
      # remove the '%' in the values
      digitStr = v.match /\d*\.*\d*/
      digitStr = digitStr[0]
      valuesArray.push parseInt digitStr
  return valuesArray

# connect to database
err, db <- mongodb.connect url

createNN = (trainingSet, callback) ->
  console.log trainingSet
  myPerceptron = new Architect.Perceptron 26, 50, 2
  myTrainer = new Trainer myPerceptron
  myTrainer.train trainingSet, do
    rate: 0.1
    iterations: 10000
    error: 0.1
    log: 1000
    cost: Trainer.cost.CROSS_ENTROPY
  testData = getInputData \ATL, \BKN
  test = myPerceptron.activate testData
  for i in test
    console.log i*200
  callback null
async.waterfall [
  # pass parameter to function 'loadTeaminfo'
  async.apply loadTeamInfo, db
  loadGameInfo
  createNN
], (err, result)->
  console.log \finish
  db.close!

/*
cursor = games.find!
err, item <- cursor.nextObject
log item
*/
