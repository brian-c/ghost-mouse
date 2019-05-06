(function() {
  const TICK_DURATION = 1000 / 60;

  async function sleep(duration = 0) {
    return new Promise(resolve => setTimeout(resolve, duration));
  }

  const realCursorTrap = document.createElement('div');
  realCursorTrap.classList.add('ghost-mouse-trap');

  addEventListener('mousemove', function(event) {
    if (!event.ghostMouse) {
      realCursorTrap.style.left = `${event.pageX}px`;
      realCursorTrap.style.top = `${event.pageY}px`;
    }
  }, true);

  let activeGhostMice = 0;

  function swallowRealEvent(event) {
    if (!event.ghostMouse) {
      event.stopPropagation();
    }
  }

  const eventsToSwallow = [
    'mousedown',
    'mousemove',
    'mouseup',
    'click'
  ];

  async function changeActiveGhostMice(change) {
    activeGhostMice += change;

    if (activeGhostMice === 0) {
      eventsToSwallow.forEach(eventName => {
        removeEventListener(eventName, swallowRealEvent, true);
      });
      delete realCursorTrap.dataset.present;
      await sleep(500);
      realCursorTrap.remove();
    } else if (activeGhostMice === 1) {
      eventsToSwallow.forEach(eventName => {
        addEventListener(eventName, swallowRealEvent, true);
      });
      document.body.appendChild(realCursorTrap);
      await sleep(1);
      realCursorTrap.dataset.present = true;
    }
  }

  class GhostMouse {
    constructor(params = {}) {
      this.element = document.createElement('div');
      this.element.classList.add('ghost-mouse');

      this.queue = [];
      this.downTarget = null;
    }

    down(rest = 250) {
      this.queue.push(this._down.bind(this, rest));
      return this;
    }

    up(rest = 250) {
      this.queue.push(this._up.bind(this, rest));
      return this;
    }

    click(rest = 500) {
      this.queue.push(this._down.bind(this, 250));
      this.queue.push(this._up.bind(this, rest));
      return this;
    }

    move(target, x = 1/2, y = 1/2, duration = 1000, rest = 100) {
      this.queue.push(this._move.bind(this, target, x, y, duration, rest));
      return this;
    }

    _triggerEvent(eventName) {
      const x = parseFloat(this.element.style.left) - pageXOffset;
      const y = parseFloat(this.element.style.top) - pageYOffset;

      this.element.style.display = 'none';
      const target = document.elementFromPoint(x, y);
      this.element.style.display = '';

      if (!target) {
        return;
      }

      const event = document.createEvent('MouseEvents');
      event.initMouseEvent(
        eventName, true, true,
        event.view, event.detail,
        x, y, x, y,
        event.ctrlKey, event.shiftKey, event.altKey, event.metaKey,
        event.button, event.relatedTarget
      );

      if (event.pageX === 0 && event.pageY === 0) {
        Object.defineProperties(event, {
          pageX: {
            get() {
              return event.clientX;
            },
          },

          pageY: {
            get() {
              return event.clientY;
            },
          },
        });
      }

      event.ghostMouse = this;

      target.dispatchEvent(event);

      return event;
    }

    async _down(rest) {
      this.element.dataset.isDown = true;
      const event = this._triggerEvent('mousedown');
      this.downTarget = event.target;
      await sleep(rest);
    }

    async _up(rest) {
      delete this.element.dataset.isDown;
      const event = this._triggerEvent('mouseup');
      if (event.target === this.downTarget) {
        this._triggerEvent('click');
      }
      this.downTarget = null;
      await sleep(rest);
    }

    async _move(target, x, y, duration, rest) {
      const startX = parseFloat(this.element.style.left);
      const startY = parseFloat(this.element.style.top);

      let targetElement = target;
      if (typeof targetElement === 'string') {
        targetElement = document.querySelector(targetElement);
      }

      const targetRect = targetElement.getBoundingClientRect();

      const endX = pageXOffset + targetRect.left + targetRect.width * x;
      const endY = pageYOffset + targetRect.top + targetRect.height * y;

      const startTime = Date.now();
      let elapsedTime = 0;
      while (elapsedTime <= duration) {
        const progress = elapsedTime / duration;
        this.element.style.left = `${(((endX - startX)) * progress) + startX}px`;
        this.element.style.top  = `${(((endY - startY)) * progress) + startY}px`;
        this._triggerEvent('mousemove');
        await sleep(TICK_DURATION);
        elapsedTime += TICK_DURATION;
      }

      await sleep(rest);
    }

    async run() {
      try {
        changeActiveGhostMice(+1);

        this.element.style.left = realCursorTrap.style.left;
        this.element.style.top = realCursorTrap.style.top;

        document.body.appendChild(this.element);
        await sleep(1);
        this.element.dataset.hasControl = true;

        await this.queue.reduce(async (previous, action) => {
          await previous;
          return await action();
        }, Promise.resolve());
      } finally {
        delete this.element.dataset.hasControl;
        await sleep(500); // Allow time for completion animation.
        this.element.remove();

        changeActiveGhostMice(-1);

        this.queue.splice(0);

        return this;
      }
    }
  }

  if (typeof window !== 'undefined') {
    window.GhostMouse = GhostMouse;
  }

  if (typeof module !== 'undefined') {
    module.exports = GhostMouse;
  }
}());
