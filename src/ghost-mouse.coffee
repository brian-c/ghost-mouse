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
  events: true
  className: ''
  fps: 30

  el: null
  queue: null

  downTarget = null

  constructor: (params = {}) ->
    @[property] = value for property, value of params

    @el = document.createElement 'div'
    @el.classList.add 'ghost-mouse'
    @el.classList.add @className if @className
    @el.style.display = 'none'
    @el.style.position = 'absolute'
    document.body.appendChild @el

    @queue = []

  run: (script) ->
    script?.call @

    @_reset 0, =>
      console.log 'Run (after reset)'
      @el.style.display = ''

      wait 10, =>
        console.log 'Add active class'
        @el.classList.add 'active'

      wait @duration, =>
        @next()
    @

  next: ->
    if @queue.length is 0
      console.log 'QUEUE EMPTY'
      wait @duration, =>
        @el.classList.remove 'active'

        wait @duration, =>
          @el.style.display = 'none'
    else
      command = @queue.shift()

      command.call @, =>
        @next()

    null

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

  # Attach interface methods that add actions to the queue.
  methods = ['down', 'up', 'click', 'move', 'reset']

  for method in methods then do (method) =>
    @::[method] = (originalArgs...) ->
      @queue.push (callArgs...) ->
        @["_#{method}"] originalArgs..., callArgs...

      @

  do: ([duration]..., fn) ->
    @queue.push (cb) ->
      fn.call @
      duration ?= @duration
      wait duration, cb

    @

  _reset: ([duration]..., cb) ->
    console.log 'GHOST MOUSE RESET'
    bodyStyle = getComputedStyle document.body
    bodyMargin = [(parseFloat bodyStyle.marginLeft), (parseFloat bodyStyle.marginTop)]

    @el.style.left = "#{mousePosition[0] - bodyMargin[0]}px"
    @el.style.top = "#{mousePosition[1] - bodyMargin[1]}px"

    duration ?= @duration
    console.log 'reset duration', duration
    wait duration, cb

  _down: ([duration]..., cb) ->
    console.log 'GHOST MOUSE DOWN', arguments
    @el.classList.add 'down'
    down = @triggerEvent 'mousedown' if @events
    @downTarget = down.target

    duration ?= @duration
    wait duration, cb

  _up: ([duration]..., cb) ->
    console.log 'GHOST MOUSE UP', arguments
    up = @triggerEvent 'mouseup' if @events
    @el.classList.remove 'down'
    @triggerEvent 'click' if @events and @downTarget is up?.target
    @downTarget = null

    duration ?= @duration
    wait duration, cb

  _click: ([duration]..., cb) ->
    console.log 'GHOST MOUSE CLICK', arguments
    @_down 250, =>
      @_up -> # No-op

    duration ?= @duration
    wait duration, cb

  _move: (target, x, y, [duration]..., cb) ->
    target = document.querySelector target if typeof target is 'string'

    console.log "GHOST MOUSE MOVE", arguments

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

    duration ?= @duration
    animationDuration = duration - 250
    ticks = (i for i in [0...animationDuration] by Math.floor 1000 / @fps)
    for tick in ticks then do (tick) =>
      wait tick, =>
        step = tick / animationDuration
        ease = Math.sin step * Math.PI
        swing = [(end[0] - start[0]) / 3 * ease, (end[1] - start[1]) / 3 * ease]
        @el.style.left = "#{(((end[0] - start[0])) * step) + start[0] + swing[0]}px"
        @el.style.top  = "#{(((end[1] - start[1])) * step) + start[1] - swing[1]}px"
        @triggerEvent 'mousemove' if @events

    @downTarget = null

    wait duration, cb

  stop: ->
    @queue.splice 0
    @

  destroy: ->
    @stop()
    @el.parentNode.removeChild @el
    null

window?.GhostMouse = GhostMouse
module?.exports = GhostMouse
