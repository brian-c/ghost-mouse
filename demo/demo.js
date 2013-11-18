window.gm = new GhostMouse();
window.gm2 = new GhostMouse({inverted: true});

window.demo = function(e) {
  window.gm.run(function() {
    this.do(0, function() {e.target.disabled = true;});
    this.move('.one', 0.5, 0.5);
    this.down();
    this.move('.three', 0.5, 0.5);
    this.up();
    this.move('.two', 0.5, 0.5);
    this.click();
    this.move('.four', 0.5, 0.5);
    this.click();
    this.do(0, function() {e.target.disabled = false;});
  });
};

window.demoChained = function(e) {
  window.gm2
    .do(0, function() {e.target.disabled = true;})
    .move('.one', 0.5, 0.5)
    .down()
    .move('.three', 0.5, 0.5)
    .up()
    .move('.two', 0.5, 0.5)
    .click()
    .move('.four', 0.5, 0.5)
    .click()
    .do(0, function() {e.target.disabled = false;})
    .run();
};
