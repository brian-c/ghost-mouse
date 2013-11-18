exec = require 'easy-exec'

task 'serve', (options) ->
  exec "coffee --compile --output . --watch ./src"
  exec "stylus --out . --watch ./src"
  exec "serveup --port #{process.env.PORT || 6057}"
