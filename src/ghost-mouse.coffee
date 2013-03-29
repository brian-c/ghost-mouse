mousePosition = [innerWidth / 2, innerHeight / 2]

addEventListener 'mousemove', (e) ->
  mousePosition[0] = e.pageX
  mousePosition[1] = e.pageY

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
  duration: 1000
  fps: 30
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
      wait 10, => @el.classList.add 'active'
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
      @move selector, x, y, => wait @duration, => @next()

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

  move: (target, x, y, cb) ->
    target = document.querySelector target if typeof target is 'string'
    console.log "GHOST MOUSE POSITION (#{x}, #{y})", target

    targetStyle = getComputedStyle target
    targetSize = [(parseFloat targetStyle.width), (parseFloat targetStyle.height)]
    targetOffset = getOffset target
    elParentOffset = getOffset @el.parentNode

    start = [
      parseFloat @el.style.left || 0
      parseFloat @el.style.top || 0
    ]

    end = [
      (x * targetSize[0]) + (targetOffset[0] - elParentOffset[0])
      (y * targetSize[1]) + (targetOffset[1] - elParentOffset[1])
    ]

    ticks = (i for i in [0...@duration] by Math.floor 1000 / @fps)
    for tick in ticks then do (tick) =>
      wait tick, =>
        step = tick / @duration
        ease = Math.sin step * Math.PI
        swing = [(end[0] - start[0]) / 3 * ease, (end[1] - start[1]) / 3 * ease]
        @el.style.left = "#{(((end[0] - start[0])) * step) + start[0] + swing[0]}px"
        @el.style.top  = "#{(((end[1] - start[1])) * step) + start[1] - swing[1]}px"

    wait @duration, => cb()

  reset: (cb) ->
    console.log 'GHOST MOUSE RESET'
    bodyStyle = getComputedStyle document.body
    bodyMargin = [(parseFloat bodyStyle.marginLeft), (parseFloat bodyStyle.marginTop)]

    @el.style.left = "#{mousePosition[0] - bodyMargin[0]}px"
    @el.style.top = "#{mousePosition[1] - bodyMargin[1]}px"

    cb()

  stop: ->
    @queue.splice 0

  destroy: ->
    @stop()
    @el.parentNode.removeChild @el

window?.GhostMouse = GhostMouse
module?.exports = GhostMouse
