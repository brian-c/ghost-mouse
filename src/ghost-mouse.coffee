mousePosition =
  x: innerWidth / 2
  y: innerHeight / 2

mouseDisablerContainer = document.createElement 'div'
mouseDisablerContainer.className = 'ghost-mouse-disabler-container'

mouseDisabler = document.createElement 'div'
mouseDisabler.className = 'ghost-mouse-disabler'

mouseDisablerContainer.appendChild mouseDisabler
document.body.appendChild mouseDisablerContainer

updateMousePosition = (e) ->
  return if e.ghostMouse?

  mousePosition.x = e.pageX
  mousePosition.y = e.pageY

  containerRect = mouseDisablerContainer.getBoundingClientRect()
  containerPosition =
    x: containerRect.left + pageXOffset
    y: containerRect.top + pageYOffset

  mouseDisabler.style.left = "#{mousePosition.x - containerPosition.x}px"
  mouseDisabler.style.top = "#{mousePosition.y - containerPosition.y}px"

document.addEventListener 'mousemove', updateMousePosition

wait = (time, fn) ->
  [time, fn] = [0, time] if typeof time is 'function'
  setTimeout fn, time

class GhostMouse
  inverted: false
  events: false

  duration: 1000
  fps: 30
  swing: 1 / 10

  isDown: false
  downTarget: null

  constructor: (params = {}) ->
    @[property] = value for property, value of params

    @el = document.createElement 'div'
    @el.className = 'ghost-mouse'
    @el.setAttribute 'data-ghost-mouse-inverted', true if @inverted
    @el.style.display = 'none'

    @container = document.createElement 'div'
    @container.className = 'ghost-mouse-container'

    @container.appendChild @el
    document.body.appendChild @container

    @queue = []

  run: (script) ->
    script?.call @

    document.body.setAttribute 'data-ghost-mouse-active', true
    document.body.setAttribute 'data-ghost-mouse-eventing', true if @events

    @_reset 0, =>
      @el.style.display = ''

      wait 10, =>
        @el.setAttribute 'data-ghost-mouse-active', true

      wait @duration, =>
        @next()
    @

  next: ->
    if @queue.length is 0
      @el.removeAttribute 'data-ghost-mouse-active'
      document.body.removeAttribute 'data-ghost-mouse-active'
      document.body.removeAttribute 'data-ghost-mouse-eventing' if @events

      wait @duration, =>
        @el.style.display = 'none'

    else
      command = @queue.shift()

      command.call @, =>
        @next()

    null

  triggerEvent: (eventName) ->
    return unless @events

    bodyRect = document.body.getBoundingClientRect()
    bodyMargin = [bodyRect.left + pageXOffset, bodyRect.top + pageYOffset]
    currentPosition = (parseFloat n for n in [@el.style.left, @el.style.top])

    [x, y] = [
      currentPosition[0] - pageXOffset
      currentPosition[1] - pageYOffset
    ]

    target = document.elementFromPoint x, y
    return unless target?

    if 'createEvent' of document
      e = document.createEvent 'MouseEvent'
      e.initMouseEvent eventName, true, true,
        e.view, e.detail,
        currentPosition[0], currentPosition[1], currentPosition[0], currentPosition[1],
        e.ctrlKey, e.shiftKey,
        e.altKey, e.metaKey,
        e.button, e.relatedTarget

    else
      document.createEventObject();
      e.eventType = eventName
      e.pageX = currentPosition[0]
      e.pageY = currentPosition[1]

    e.ghostMouse = @

    if 'dispatchEvent' of target
      target.dispatchEvent e
    else
      target.fireEvent "on#{eventName}", event

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

  drag: (target, x, y, [duration]..., cb) ->
    @queue.push (cb) ->
      duration ?= @duration
      @_down 100, =>
        @_move target, x, y, duration - 200, =>
          @_up 100, cb

    @

  _reset: ([duration]..., cb) ->
    containerRect = @container.getBoundingClientRect()

    @el.style.left = "#{mousePosition.x - (containerRect.left + pageXOffset)}px"
    @el.style.top = "#{mousePosition.y - (containerRect.top + pageYOffset)}px"

    duration ?= @duration
    wait duration, cb

  _down: ([duration]..., cb) ->
    @isDown = true
    @el.setAttribute 'data-ghost-mouse-down', true
    down = @triggerEvent 'mousedown'
    @downTarget = down?.target

    duration ?= @duration
    wait duration, cb

  _up: ([duration]..., cb) ->
    @isDown = false
    @el.removeAttribute 'data-ghost-mouse-down'
    up = @triggerEvent 'mouseup'
    @triggerEvent 'click' if @downTarget is up?.target
    @downTarget = null

    duration ?= @duration
    wait duration, cb

  _click: ([duration]..., cb) ->
    @_down 250, =>
      @_up -> # No-op

    duration ?= @duration
    wait duration, cb

  _move: (target, x, y, [duration]..., cb) ->
    target = document.querySelector target if typeof target is 'string'

    targetStyle = getComputedStyle target
    targetSize = [(parseFloat targetStyle.width), (parseFloat targetStyle.height)]
    targetOffset = target.getBoundingClientRect()
    elParentOffset = @container.getBoundingClientRect()

    start =
      x: parseFloat @el.style.left || 0
      y: parseFloat @el.style.top || 0

    end = [
      (x * targetSize[0]) + ((targetOffset.left + pageXOffset) - (elParentOffset.left + pageXOffset))
      (y * targetSize[1]) + ((targetOffset.top + pageYOffset) - (elParentOffset.top + pageYOffset))
    ]

    duration ?= @duration
    animationDuration = duration - 250
    ticks = (i for i in [0...animationDuration] by Math.floor 1000 / @fps)
    for tick in ticks then do (tick) =>
      wait tick, =>
        step = tick / animationDuration
        ease = Math.sin step * Math.PI
        swing =
          x: (end[0] - start.x) * @swing * ease
          y: (end[1] - start.y) * @swing * ease

        left = "#{(((end[0] - start.x)) * step) + start.x + swing.x}px"
        top  = "#{(((end[1] - start.y)) * step) + start.y - swing.y}px"

        @el.style.left = left
        @el.style.top  = top

        @triggerEvent 'mousemove'

        if @isDown and not @events
          trail = document.createElement 'div'
          trail.className = 'ghost-mouse-trail'
          trail.style.left = left
          trail.style.top = top
          @container.appendChild trail
          wait duration / 2, =>
            @container.removeChild trail

    @downTarget = null

    wait duration, cb

  stop: ->
    @queue.splice 0
    @

  destroy: ->
    @stop()
    @container.parentNode.removeChild @container
    null

window?.GhostMouse = GhostMouse
module?.exports = GhostMouse
