Server = require './server'
Path   = require 'path'
Cli    = require('cli').enable('status', 'version')
Fs     = require 'fs'

# Command Line Setup
module.exports = entry_point = () ->
  Cli.enable 'version'
#  Cli.setUsage 'node start.js -c <config json>'
  Cli.setApp 'HoardDaemon', '0.1.0'
  Cli.parse
    'host': ['h', 'Carbon hostname', 'string', "metrics.#{process.env['CLOUD_DOMAIN']}"]
    'port': ['p', 'Carbon port', 'number', 2003]

  Cli.main (args, options) ->
    # console.dir options
    # create config
    conf =
      cloudname:    process.env['CLOUD_NAME']
      hostname:     process.env['NODE_ID']
      scriptPath:   "/home/port6379/hoardd/scripts"
      carbonHost:   options.host
      carbonPort:   options.port
      sampleInterval: 10
      sendEach: 6
      maxFailedSens: 10000

    console.dir conf
    # process.exit(1)

    hoard = new Server conf, Cli
    hoard.load_scripts()

    hoard.on 'run', hoard.run_scripts

    hoard.emit 'run'
    setInterval(->
      hoard.emit 'run'
    ,conf.sampleInterval * 1000)

    Cli.info "HoardD started. Samples each #{conf.sampleInterval} seconds. Sending to graphite each #{conf.sendEach} samplings"
