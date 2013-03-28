window.gm = new GhostMouse

window.gmDemo = (e) ->
  GhostMouse.go [
    -> e.target.disabled = true
    '.thing.one 0.5 0.5'
    'down'
    '.thing.two 0.25 0.25'
    'up'
    '.thing.three 0.75 0.75'
    'click'
    -> e.target.disabled = false
  ]
