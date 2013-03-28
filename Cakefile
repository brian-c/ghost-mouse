{spawn} = require 'child_process'

exec = (fullCommand) ->
  [command, args...] = fullCommand.split ' '
  child = spawn command, args
  child.stdout.on 'data', process.stdout.write.bind process.stdout
  child.stderr.on 'data', process.stderr.write.bind process.stderr

coffee = [
  './src/ghost-mouse.coffee'
]

styl = [
  './src/ghost-mouse.styl'
]

task 'watch', ->
  exec "coffee --compile --output . --watch ./src"
  exec "stylus --out . --watch ./src"

task 'serve', (options) ->
  invoke 'watch'
  exec "silver server --port #{process.env.PORT || 6057}"
