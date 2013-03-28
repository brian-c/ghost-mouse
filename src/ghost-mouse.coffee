mouse = [NaN, NaN]

addEventListener 'mousemove', (e) ->
  mouse[0] = e.pageX
  mouse[1] = e.pageY

wait = (time, fn) ->
  [time, fn] = [0, time] if typeof time is 'function'
  setTimeout fn, time

getOffset = (el) ->
  offsetParent = el
  offset = [0, 0]
  while offsetParent?
    offset[0] += offsetParent.offsetLeft
    offset[1] += offsetParent.offsetTop
    offsetParent = offsetParent.offsetParent

  offset

class GhostMouse
  @genericInstance: null

  @go: (commands) ->
    @genericInstance ?= new @
    @genericInstance.go arguments...

  @stop: ->
    @genericInstance?.stop arguments...

  duration: 1000
  className: ''

  el: null
  queue: null

  constructor: (commands) ->
    @el = document.createElement 'div'
    @el.classList.add 'ghost-mouse'
    @el.classList.add @className if @className
    @el.style.display = 'none'
    @el.style.position = 'absolute'
    document.body.appendChild @el

    @queue = []

    @go commands if commands?

  go: (commands) ->
    @queue.push commands...

    @reset =>
      @el.style.display = ''
      wait => @el.classList.add 'active'
      wait @duration, => @next()

  next: ->
    if @queue.length is 0
      console.log 'QUEUE EMPTY'
      @el.classList.remove 'active'
      wait @duration, => @el.style.display = 'none'
      return

    command = @queue.shift()

    if typeof command is 'function'
      command.call @
      @next()

    else if command of @
        @[command] => wait @duration, => @next()

    else
      [selector..., x, y] = command.split /\s+/
      selector = selector.join ' '
      @position selector, x, y, => wait @duration, => @next()

  down: (cb) ->
    console.log 'GHOST MOUSE DOWN'
    @el.classList.add 'down'
    cb()

  up: (cb) ->
    console.log 'GHOST MOUSE UP'
    @el.classList.remove 'down'
    cb()

  click: (cb) ->
    console.log 'GHOST MOUSE CLICK'
    @down =>
      wait 250, =>
        @up =>
          cb()

  position: (target, x, y, cb) ->
    # Position at target x, y
    target = document.querySelector target if typeof target is 'string'
    console.log "GHOST MOUSE POSITION (#{x}, #{y})", target

    targetStyle = getComputedStyle target

    targetSize = [(parseFloat targetStyle.width), (parseFloat targetStyle.height)]
    targetOffset = getOffset target
    elParentOffset = getOffset @el.parentNode

    @el.style.left = (x * targetSize[0]) + (targetOffset[0] - elParentOffset[0])
    @el.style.top  = (y * targetSize[1]) + (targetOffset[1] - elParentOffset[1])

    cb()

  reset: (cb) ->
    console.log 'GHOST MOUSE RESET'
    bodyStyle = getComputedStyle document.body
    bodySize = [(parseFloat bodyStyle.width), (parseFloat bodyStyle.height)]
    bodyMargin = [(parseFloat bodyStyle.marginLeft), (parseFloat bodyStyle.marginTop)]

    @position document.body, ((mouse[0] - bodyMargin[0]) / bodySize[0]), ((mouse[1] - bodyMargin[1]) / bodySize[1]), cb

  stop: ->
    @queue.splice 0

  destroy: ->
    @stop()
    @el.parentNode.removeChild @el

window?.GhostMouse = GhostMouse
module?.exports = GhostMouse
