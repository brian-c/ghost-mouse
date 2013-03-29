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
  events: true

  el: null
  queue: null

  _willClick = null

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

  triggerEvent: (eventName) ->
    e = document.createEvent 'MouseEvent'

    bodyStyle = getComputedStyle document.body
    bodyMargin = (parseFloat n for n in [bodyStyle.marginLeft, bodyStyle.marginTop])
    currentPosition = (parseFloat n for n in [@el.style.left, @el.style.top])
    [x, y] = [bodyMargin[0] + currentPosition[0], bodyMargin[1] + currentPosition[1]]

    e.initMouseEvent eventName, true, true,
      e.view, e.detail,
      x, y, x, y
      e.ctrlKey, e.shiftKey,
      e.altKey, e.metaKey,
      e.button, e.relatedTarget

    target = document.elementFromPoint x, y
    target.dispatchEvent e

    # console.log "TRIGGERING EVENT #{eventName} ON", target, "AT #{x}, #{y}"

    e

  down: (cb) ->
    console.log 'GHOST MOUSE DOWN'
    @el.classList.add 'down'
    down = @triggerEvent 'mousedown' if @events
    @_willClick = down.target
    cb()

  up: (cb) ->
    console.log 'GHOST MOUSE UP'
    up = @triggerEvent 'mouseup' if @events
    @el.classList.remove 'down'
    @triggerEvent 'click' if @_willClick is up?.target
    @_willClick = null
    cb()

  click: (cb) ->
    console.log 'GHOST MOUSE CLICK'
    @down =>
      wait 250, =>
        @up =>
          cb()

  move: (target, x, y, cb) ->
    target = document.querySelector target if typeof target is 'string'
    console.log "GHOST MOUSE MOVE (#{x}, #{y})", target

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
        @triggerEvent 'mousemove' if @events

    @_willClick = null

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
