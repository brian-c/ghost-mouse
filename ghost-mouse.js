// Generated by CoffeeScript 1.6.2
(function() {
  var GhostMouse, bodyStyle, getOffset, killEvent, mouseDisabler, mousePosition, updateMousePosition, wait,
    __slice = [].slice;

  if (!('classList' in document.body)) {
    throw new Error('Ghost Mouse need Element::classList or a polyfill.');
  }

  mousePosition = [innerWidth / 2, innerHeight / 2];

  bodyStyle = getComputedStyle(document.body);

  updateMousePosition = function(e) {
    var bodyMargin;

    if (e.ghostMouse != null) {
      return;
    }
    mousePosition[0] = e.pageX;
    mousePosition[1] = e.pageY;
    bodyMargin = [parseFloat(bodyStyle.marginLeft), parseFloat(bodyStyle.marginTop)];
    mouseDisabler.style.left = "" + (mousePosition[0] - bodyMargin[0]) + "px";
    return mouseDisabler.style.top = "" + (mousePosition[1] - bodyMargin[1]) + "px";
  };

  killEvent = function(e) {
    e.preventDefault();
    return e.stopPropagation();
  };

  mouseDisabler = document.createElement('div');

  document.body.appendChild(mouseDisabler);

  mouseDisabler.classList.add('ghost-mouse-disabler');

  mouseDisabler.addEventListener('click', killEvent);

  mouseDisabler.addEventListener('mouseup', killEvent);

  mouseDisabler.addEventListener('mousedown', killEvent);

  mouseDisabler.addEventListener('mousemove', function(e) {
    killEvent(e);
    return updateMousePosition(e);
  });

  document.addEventListener('mousemove', updateMousePosition);

  wait = function(time, fn) {
    var _ref;

    if (typeof time === 'function') {
      _ref = [0, time], time = _ref[0], fn = _ref[1];
    }
    return setTimeout(fn, time);
  };

  getOffset = function(el) {
    var offset, offsetParent;

    offsetParent = el;
    offset = [0, 0];
    while (offsetParent != null) {
      offset[0] += offsetParent.offsetLeft;
      offset[1] += offsetParent.offsetTop;
      offsetParent = offsetParent.offsetParent;
    }
    return offset;
  };

  GhostMouse = (function() {
    var downTarget, method, methods, _fn, _i, _len,
      _this = this;

    GhostMouse.prototype.duration = 1000;

    GhostMouse.prototype.events = true;

    GhostMouse.prototype.className = '';

    GhostMouse.prototype.inverted = false;

    GhostMouse.prototype.fps = 30;

    GhostMouse.prototype.el = null;

    GhostMouse.prototype.queue = null;

    downTarget = null;

    function GhostMouse(params) {
      var property, value;

      if (params == null) {
        params = {};
      }
      for (property in params) {
        value = params[property];
        this[property] = value;
      }
      this.el = document.createElement('div');
      this.el.classList.add('ghost-mouse');
      if (this.className) {
        this.el.classList.add(this.className);
      }
      if (this.inverted) {
        this.el.classList.add('inverted');
      }
      this.el.style.display = 'none';
      document.body.appendChild(this.el);
      this.queue = [];
    }

    GhostMouse.prototype.run = function(script) {
      var _this = this;

      if (script != null) {
        script.call(this);
      }
      document.body.classList.add('ghost-mouse-active');
      this._reset(0, function() {
        console.log('Run (after reset)');
        _this.el.style.display = '';
        wait(10, function() {
          console.log('Add active class');
          return _this.el.classList.add('active');
        });
        return wait(_this.duration, function() {
          return _this.next();
        });
      });
      return this;
    };

    GhostMouse.prototype.next = function() {
      var command,
        _this = this;

      if (this.queue.length === 0) {
        console.log('QUEUE EMPTY');
        wait(this.duration, function() {
          _this.el.classList.remove('active');
          document.body.classList.remove('ghost-mouse-active');
          return wait(_this.duration, function() {
            return _this.el.style.display = 'none';
          });
        });
      } else {
        command = this.queue.shift();
        command.call(this, function() {
          return _this.next();
        });
      }
      return null;
    };

    GhostMouse.prototype.triggerEvent = function(eventName) {
      var bodyMargin, currentPosition, e, n, target, x, y, _ref;

      if (!this.events) {
        return;
      }
      bodyStyle = getComputedStyle(document.body);
      bodyMargin = (function() {
        var _i, _len, _ref, _results;

        _ref = [bodyStyle.marginLeft, bodyStyle.marginTop];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          n = _ref[_i];
          _results.push(parseFloat(n));
        }
        return _results;
      })();
      currentPosition = (function() {
        var _i, _len, _ref, _results;

        _ref = [this.el.style.left, this.el.style.top];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          n = _ref[_i];
          _results.push(parseFloat(n));
        }
        return _results;
      }).call(this);
      _ref = [currentPosition[0] - pageXOffset, currentPosition[1] - pageYOffset], x = _ref[0], y = _ref[1];
      target = document.elementFromPoint(x, y);
      if (target == null) {
        return;
      }
      if ('createEvent' in document) {
        e = document.createEvent('MouseEvent');
        e.initMouseEvent(eventName, true, true, e.view, e.detail, currentPosition[0], currentPosition[1], currentPosition[0], currentPosition[1], e.ctrlKey, e.shiftKey, e.altKey, e.metaKey, e.button, e.relatedTarget);
      } else {
        document.createEventObject();
        e.eventType = eventName;
        e.pageX = currentPosition[0];
        e.pageY = currentPosition[1];
      }
      e.ghostMouse = this;
      if ('dispatchEvent' in target) {
        target.dispatchEvent(e);
      } else {
        target.fireEvent("on" + eventName, event);
      }
      return e;
    };

    methods = ['down', 'up', 'click', 'move', 'reset'];

    _fn = function(method) {
      return GhostMouse.prototype[method] = function() {
        var originalArgs;

        originalArgs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.queue.push(function() {
          var callArgs;

          callArgs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return this["_" + method].apply(this, __slice.call(originalArgs).concat(__slice.call(callArgs)));
        });
        return this;
      };
    };
    for (_i = 0, _len = methods.length; _i < _len; _i++) {
      method = methods[_i];
      _fn(method);
    }

    GhostMouse.prototype["do"] = function() {
      var duration, fn, _arg, _j;

      _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), fn = arguments[_j++];
      duration = _arg[0];
      this.queue.push(function(cb) {
        console.log('GHOST MOUSE DO', arguments);
        fn.call(this);
        if (duration == null) {
          duration = this.duration;
        }
        return wait(duration, cb);
      });
      return this;
    };

    GhostMouse.prototype.drag = function() {
      var cb, duration, target, x, y, _arg, _j;

      target = arguments[0], x = arguments[1], y = arguments[2], _arg = 5 <= arguments.length ? __slice.call(arguments, 3, _j = arguments.length - 1) : (_j = 3, []), cb = arguments[_j++];
      duration = _arg[0];
      this.queue.push(function(cb) {
        var _this = this;

        console.log('GHOST MOUSE DRAG', arguments);
        if (duration == null) {
          duration = this.duration;
        }
        return this._down(100, function() {
          return _this._move(target, x, y, duration - 200, function() {
            return _this._up(100, cb);
          });
        });
      });
      return this;
    };

    GhostMouse.prototype._reset = function() {
      var bodyMargin, cb, duration, _arg, _j;

      _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), cb = arguments[_j++];
      duration = _arg[0];
      console.log('GHOST MOUSE RESET');
      bodyStyle = getComputedStyle(document.body);
      bodyMargin = [parseFloat(bodyStyle.marginLeft), parseFloat(bodyStyle.marginTop)];
      this.el.style.left = "" + (mousePosition[0] - bodyMargin[0]) + "px";
      this.el.style.top = "" + (mousePosition[1] - bodyMargin[1]) + "px";
      if (duration == null) {
        duration = this.duration;
      }
      console.log('reset duration', duration);
      return wait(duration, cb);
    };

    GhostMouse.prototype._down = function() {
      var cb, down, duration, _arg, _j;

      _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), cb = arguments[_j++];
      duration = _arg[0];
      console.log('GHOST MOUSE DOWN', arguments);
      this.el.classList.add('down');
      down = this.triggerEvent('mousedown');
      this.downTarget = down.target;
      if (duration == null) {
        duration = this.duration;
      }
      return wait(duration, cb);
    };

    GhostMouse.prototype._up = function() {
      var cb, duration, up, _arg, _j;

      _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), cb = arguments[_j++];
      duration = _arg[0];
      console.log('GHOST MOUSE UP', arguments);
      up = this.triggerEvent('mouseup');
      this.el.classList.remove('down');
      if (this.downTarget === (up != null ? up.target : void 0)) {
        this.triggerEvent('click');
      }
      this.downTarget = null;
      if (duration == null) {
        duration = this.duration;
      }
      return wait(duration, cb);
    };

    GhostMouse.prototype._click = function() {
      var cb, duration, _arg, _j,
        _this = this;

      _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), cb = arguments[_j++];
      duration = _arg[0];
      console.log('GHOST MOUSE CLICK', arguments);
      this._down(250, function() {
        return _this._up(function() {});
      });
      if (duration == null) {
        duration = this.duration;
      }
      return wait(duration, cb);
    };

    GhostMouse.prototype._move = function() {
      var animationDuration, cb, duration, elParentOffset, end, i, start, target, targetOffset, targetSize, targetStyle, tick, ticks, x, y, _arg, _fn1, _j, _k, _len1,
        _this = this;

      target = arguments[0], x = arguments[1], y = arguments[2], _arg = 5 <= arguments.length ? __slice.call(arguments, 3, _j = arguments.length - 1) : (_j = 3, []), cb = arguments[_j++];
      duration = _arg[0];
      if (typeof target === 'string') {
        target = document.querySelector(target);
      }
      console.log("GHOST MOUSE MOVE", arguments);
      targetStyle = getComputedStyle(target);
      targetSize = [parseFloat(targetStyle.width), parseFloat(targetStyle.height)];
      targetOffset = getOffset(target);
      elParentOffset = getOffset(this.el.parentNode);
      start = [parseFloat(this.el.style.left || 0), parseFloat(this.el.style.top || 0)];
      end = [(x * targetSize[0]) + (targetOffset[0] - elParentOffset[0]), (y * targetSize[1]) + (targetOffset[1] - elParentOffset[1])];
      console.log('Moving to', JSON.stringify(end));
      if (duration == null) {
        duration = this.duration;
      }
      animationDuration = duration - 250;
      ticks = (function() {
        var _k, _ref, _results;

        _results = [];
        for (i = _k = 0, _ref = Math.floor(1000 / this.fps); _ref > 0 ? _k < animationDuration : _k > animationDuration; i = _k += _ref) {
          _results.push(i);
        }
        return _results;
      }).call(this);
      _fn1 = function(tick) {
        return wait(tick, function() {
          var ease, step, swing;

          step = tick / animationDuration;
          ease = Math.sin(step * Math.PI);
          swing = [(end[0] - start[0]) / 3 * ease, (end[1] - start[1]) / 3 * ease];
          _this.el.style.left = "" + (((end[0] - start[0]) * step) + start[0] + swing[0]) + "px";
          _this.el.style.top = "" + (((end[1] - start[1]) * step) + start[1] - swing[1]) + "px";
          return _this.triggerEvent('mousemove');
        });
      };
      for (_k = 0, _len1 = ticks.length; _k < _len1; _k++) {
        tick = ticks[_k];
        _fn1(tick);
      }
      this.downTarget = null;
      return wait(duration, cb);
    };

    GhostMouse.prototype.stop = function() {
      this.queue.splice(0);
      return this;
    };

    GhostMouse.prototype.destroy = function() {
      this.stop();
      this.el.parentNode.removeChild(this.el);
      return null;
    };

    return GhostMouse;

  }).call(this);

  if (typeof window !== "undefined" && window !== null) {
    window.GhostMouse = GhostMouse;
  }

  if (typeof module !== "undefined" && module !== null) {
    module.exports = GhostMouse;
  }

}).call(this);
