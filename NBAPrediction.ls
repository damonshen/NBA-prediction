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
    getMaxMinInTeamFieds!
    callback null, db, allTeamsInfo

_teamFieldRange = {}
getMaxMinInTeamFieds = ->
  fieldRange = {}
  # iterate for all teams
  for teamName, teamData of _teamsInfo
    # iterate for all SPLITs of teams
    for split, teamRowData of teamData
      # iterate all fields in the SPLIT
      for fieldName, fieldValue of teamRowData
        if fieldName is \SPLIT
          continue
        digitStr = fieldValue.match /\d*\.*\d*/
        digitStr = digitStr[0]
        fieldValue = parseFloat fieldValue
        teamRowData[fieldName] = fieldValue
        if fieldName not of fieldRange
          fieldRange[fieldName] =
            * max: fieldValue
              min: fieldValue
        else
          if fieldValue > fieldRange[fieldName][\max]
            fieldRange[fieldName][\max] = fieldValue
          if fieldValue < fieldRange[fieldName][\min]
            fieldRange[fieldName][\min] = fieldValue
  _teamFieldRange := fieldRange




# load the game information and add the team information
# to generate the input data for neural network
loadGameInfo = (db, teamsInfo, callback) ->
  # the data of neural network
  dataSet = []
  gameCollection = db.collection('games')
  err, games <- gameCollection.find {}, {limit: 10} .toArray
  console.log games.length
  for game in games
    gameInput = []
    #console.log game.awayTeam.name, ' vs ', game.homeTeam.name
    awayName = game.awayTeam.name
    homeName = game.homeTeam.name
    if awayName is \DAL or homeName is \DAL
      continue
    inputData = getInputData awayName, homeName
    outputData = getOutputData game
    data = generateData inputData, outputData
    dataSet.push data
  callback null, dataSet

generateData = (inputArray, outputArray) ->
  data =
    * input: inputArray
      output: outputArray
  log data
  return data

getInputData = (awayName, homeName) ->
  # get the teams information
  awayTeamInfo =  _teamsInfo[awayName]['Road']
  homeTeamInfo =  _teamsInfo[homeName]['Home']
  # merge the object into array and remove the '%'
  awayTeamValuesArray = getNormalizeValueArray awayTeamInfo
  homeTeamValuesArray = getNormalizeValueArray homeTeamInfo

  # concat two array
  inputArray = awayTeamValuesArray.concat homeTeamValuesArray
  #console.log inputArray
  return inputArray

getAvgStats = (array) ->


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


  output = if awayFinal > homeFinal then [1 0] else [0 1]
  /*
  output.push awayFirst
  output.push awayFinal
  output.push homeFirst
  output.push homeFinal
  # normalize the data
  output = do
    numStr <- _.map output
    num = parseFloat numStr
    num = (num - 50) / (150 - 50)
  */
  return output
  /*
  awayFinal = parseFloat awayFinal
  homeFinal = parseFloat homeFinal
  output.push (awayFinal + homeFinal)/300
  return output
  */


# set the fields for input
validFields = [\PTS ]
# merge the values of Objects to an array
getNormalizeValueArray = (array) ->
  valuesArray = []
  for fieldName, fieldValue of array
    #if fieldName is not \SPLIT
    if fieldName in validFields
      range = _teamFieldRange[fieldName]
      max = range.max
      min = range.min
      normalizeValue = (fieldValue - min) / (max - min)
      valuesArray.push  normalizeValue
  return valuesArray

# connect to database
err, db <- mongodb.connect url

createNN = (trainingSet, callback) ->
  inputSize = validFields.length
  myPerceptron = new Architect.Perceptron inputSize, 1, 2
  myTrainer = new Trainer myPerceptron
  myTrainer.train trainingSet, do
    rate: 0.1
    iterations: 1000
    error: 0.1
    log: 100
  testData = [1 0]
  log testData
  testResult = myPerceptron.activate testData
  test2 = [0 1]
  testresult2 = myPerceptron.activate test2
  log test2
  for i in testResult
    console.log i
  for i in testresult2
    console.log i
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
