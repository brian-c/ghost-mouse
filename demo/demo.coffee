window.gm = new GhostMouse
window.gm2 = new GhostMouse inverted: true

window.demo = (e) ->
  window.gm.run ->
    @do 0, -> e.target.disabled = true
    @move '.one', 0.5, 0.5
    @down()
    @move '.three', 0.5, 0.5
    @up()
    @move '.two', 0.5, 0.5
    @click()
    @move '.four', 0.5, 0.5
    @click()
    @do 0, -> e.target.disabled = false

window.demoChained = (e) ->
  window.gm2
    .do(0, -> e.target.disabled = true)
    .move('.one', 0.5, 0.5)
    .down()
    .move('.three', 0.5, 0.5)
    .up()
    .move('.two', 0.5, 0.5)
    .click()
    .move('.four', 0.5, 0.5)
    .click()
    .do(0, -> e.target.disabled = false)
    .run()
