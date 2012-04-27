Redis = require 'redis'
Fs = require 'fs'

# Metrics to get from the client_info object
metrics = ['uptime_in_seconds', 'uptime_in_days', 'connected_clients',
           'connected_slaves', 'blocked_clients', 'used_memory', 'used_memory_peak', 'changes_since_last_save',
           'total_connections_received', 'total_commands_processed'
          ]

module.exports = (server) ->
  run = () ->
    server.cli.debug "Running the redis plugin"

    base = '/home/port6379/instances'
    for instance in Fs.readdirSync base
      envfile = "#{base}/#{instance}/instance.env"
      server.cli.debug "Found instance #{envfile}"
      
      # read env file and extract auth, port
      env = Fs.readFileSync(envfile,'utf-8')
      for line in env.split('\n')
        port = parseInt(line.split(/\=/)[1]) if line.match /^port/
        auth = line.split(/\=/)[1] if line.match /^auth/

      #server.cli.debug "Port: #{port} Auth: #{auth}"

      conn = Redis.createClient(port)
      conn.auth(auth)
      fn = (conn,instance) ->
        conn.on 'ready', ->
          metricPrefix = "#{server.cloudname}.redis.#{instance.replace(':','')}"
          server.push_metric("#{metricPrefix}.#{key}",
                             value) for key, value of conn.server_info when key in metrics
          conn.end()

        conn.on 'error', (error) ->
          server.cli.error "Error when connect to Redis: #{error}"

      fn(conn,instance)