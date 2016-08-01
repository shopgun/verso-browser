(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Verso = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
var Events,
  slice = [].slice;

module.exports = Events = (function() {
  function Events() {
    this._events = {};
    return;
  }

  Events.prototype.on = function(event, fn) {
    this._events[event] = this._events[event] || [];
    this._events[event].push(fn);
  };

  Events.prototype.off = function(event, fn) {
    var fns;
    fns = this._events[event] || [];
    fns.splice(fns.indexOf(fn), 1);
  };

  Events.prototype.trigger = function() {
    var args, event;
    event = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    this._events[event] = this._events[event] || [];
    this._events[event].forEach((function(_this) {
      return function(fn) {
        fn.apply(_this, args);
      };
    })(this));
  };

  return Events;

})();


},{}],2:[function(_dereq_,module,exports){
var Interactivity,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

module.exports = Interactivity = (function() {
  Interactivity.prototype.defaults = {
    pan: true,
    swipeDirection: 'horizontal',
    swipeVelocity: 0.3,
    swipeThreshold: 10,
    maxZoomScale: 3,
    minZoomScale: 1,
    keysPrev: [8, 33, 37, 38],
    keysNext: [13, 32, 34, 39, 40]
  };

  function Interactivity(verso, options) {
    var key, ref, ref1, value;
    this.verso = verso;
    if (options == null) {
      options = {};
    }
    this.keyup = bind(this.keyup, this);
    ref = this.defaults;
    for (key in ref) {
      value = ref[key];
      this[key] = (ref1 = options[key]) != null ? ref1 : value;
    }
    this.panning = false;
    this.zoomScale = 1;
    this.activePointers = [];
    this.bindEvents();
    return;
  }

  Interactivity.prototype.bindEvents = function() {
    this.verso.el.addEventListener('keyup', this.keyup.bind(this), false);
    this.verso.el.addEventListener('touchstart', this.pointerStart.bind(this), false);
    this.verso.el.addEventListener('touchmove', this.pointerMove.bind(this), false);
    this.verso.el.addEventListener('touchend', this.pointerEnd.bind(this), false);
    this.verso.el.addEventListener('touchcancel', this.pointerEnd.bind(this), false);
  };

  Interactivity.prototype.getTransform = function(el) {
    var style, transform, values;
    style = window.getComputedStyle(el, null);
    transform = style['transform'];
    values = transform !== 'none' ? transform.split('(')[1].split(')')[0].split(',') : null;
    return values;
  };

  Interactivity.prototype.zoom = function(scale, x, y) {
    var pageEl, scrollChild;
    pageEl = this.verso.pages[this.verso.pageIndex];
    scrollChild = pageEl.querySelector('.verso__scroll-child');
    if (scrollChild != null) {
      scrollChild.style.transform = "scale3d(" + scale + ", " + scale + ", 1)";
    }
    this.zoomScale = scale;
  };

  Interactivity.prototype.keyup = function(e) {
    var ref, ref1;
    if (ref = e.keyCode, indexOf.call(this.keysPrev, ref) >= 0) {
      this.verso.prev();
    } else if (ref1 = e.keyCode, indexOf.call(this.keysNext, ref1) >= 0) {
      this.verso.next();
    }
  };

  Interactivity.prototype.pointerStart = function(e) {
    var pageEl;
    e.preventDefault();
    pageEl = e.target;
    while (!pageEl.className.match(/\bverso__page\b/) && (pageEl.parentNode != null)) {
      pageEl = pageEl.parentNode;
    }
    this.panPageIndex = this.verso.pages.indexOf(pageEl);
    this.panCurrentTransform = this.getTransform(this.verso.pages[this.panPageIndex]);
    this.panning = true;
    this.startX = e.pageX;
    this.pointerMove(e);
    this.verso.el.dataset.panning = true;
  };

  Interactivity.prototype.pointerMove = function(e) {
    var currEl, deltaX, deltaY, height, matrixX, matrixY, nextEl, prevEl, width, x, y;
    if (this.panning === false) {
      return;
    }
    e.preventDefault();
    prevEl = this.verso.pages[this.panPageIndex - 1];
    currEl = this.verso.pages[this.panPageIndex];
    nextEl = this.verso.pages[this.panPageIndex + 1];
    width = this.verso.el.offsetWidth;
    height = this.verso.el.offsetHeight;
    deltaX = e.pageX - this.startX;
    deltaY = e.deltaY;
    matrixX = this.panCurrentTransform != null ? +this.panCurrentTransform[4] : 0;
    matrixY = this.panCurrentTransform != null ? +this.panCurrentTransform[5] : 0;
    x = {
      prev: 0,
      curr: 0,
      next: 0
    };
    y = {
      prev: 0,
      curr: 0,
      next: 0
    };
    if (this.swipeDirection === 'horizontal') {
      x.prev = -width + matrixX + deltaX;
      x.curr = matrixX + deltaX;
      x.next = width + matrixX + deltaX;
    } else if (this.swipeDirection === 'vertical') {
      y.prev = -height + matrixY + deltaY;
      y.curr = matrixY + deltaY;
      y.next = height + matrixY + deltaY;
    }
    console.log(this.panCurrentTransform, x.curr);
    if (prevEl != null) {
      prevEl.style.transform = "translate3d(" + x.prev + "px, " + y.prev + "px, 0)";
    }
    currEl.style.transform = "translate3d(" + x.curr + "px, " + y.curr + "px, 0)";
    if (nextEl != null) {
      nextEl.style.transform = "translate3d(" + x.next + "px, " + y.next + "px, 0)";
    }
  };

  Interactivity.prototype.pointerEnd = function(e) {
    var currEl, deltaX, nextEl, prevEl;
    deltaX = e.pageX - this.startX;
    if (this.panning === true) {
      prevEl = this.verso.pages[this.panPageIndex - 1];
      currEl = this.verso.pages[this.panPageIndex];
      nextEl = this.verso.pages[this.panPageIndex + 1];
      this.verso.el.dataset.panning = false;
      if (prevEl != null) {
        prevEl.style.transform = '';
      }
      currEl.style.transform = '';
      if (nextEl != null) {
        nextEl.style.transform = '';
      }
    }
    if (this.swipeDirection === 'horizontal') {
      if (deltaX <= -this.swipeThreshold) {
        this.verso.next();
      } else if (deltaX >= this.swipeThreshold) {
        this.verso.prev();
      }
    } else if (this.swipeDirection === 'vertical') {
      return;
    }
  };

  return Interactivity;

})();


},{}],3:[function(_dereq_,module,exports){
var Navigation;

module.exports = Navigation = (function() {
  function Navigation(verso) {
    this.verso = verso;
    this.prevEl = this.verso.el.querySelector('.verso__navigation[data-direction="previous"]');
    this.nextEl = this.verso.el.querySelector('.verso__navigation[data-direction="next"]');
    this.verso.on('change', this.updateNav.bind(this));
    this.bindEvents();
    this.updateNav();
    return;
  }

  Navigation.prototype.bindEvents = function() {
    this.prevEl.addEventListener('click', (function(_this) {
      return function() {
        return _this.verso.prev();
      };
    })(this));
    this.nextEl.addEventListener('click', (function(_this) {
      return function() {
        return _this.verso.next();
      };
    })(this));
  };

  Navigation.prototype.updateNav = function() {
    var count, index;
    index = this.verso.pageIndex;
    count = this.verso.getPageCount();
    this.prevEl.style.opacity = index === 0 ? 0 : 1;
    this.nextEl.style.opacity = index === count - 1 ? 0 : 1;
  };

  return Navigation;

})();


},{}],4:[function(_dereq_,module,exports){
var Progress;

module.exports = Progress = (function() {
  function Progress(verso) {
    this.verso = verso;
    this.el = this.verso.el.querySelector('.verso-progress__inner');
    this.verso.on('change', this.updateProgress.bind(this));
    this.updateProgress();
    return;
  }

  Progress.prototype.updateProgress = function() {
    var progress;
    progress = parseInt((this.verso.pageIndex + 1) / this.verso.getPageCount() * 100);
    this.el.style.width = progress + "%";
  };

  return Progress;

})();


},{}],5:[function(_dereq_,module,exports){
var Status;

module.exports = Status = (function() {
  function Status(verso, formatter1) {
    this.verso = verso;
    this.formatter = formatter1;
    this.el = this.verso.el.querySelector('.verso__status');
    this.verso.on('change', this.updateStatus.bind(this));
    this.updateStatus();
    return;
  }

  Status.prototype.updateStatus = function() {
    var count, el, formatter, index, value;
    index = this.verso.pageIndex;
    count = this.verso.getPageCount();
    el = this.verso.pages[index];
    formatter = typeof this.formatter === 'function' ? this.formatter : this.defaultFormatter;
    value = formatter(el, index, count);
    this.el.textContent = value;
  };

  Status.prototype.defaultFormatter = function(el, index, count) {
    return (index + 1) + " / " + count;
  };

  return Status;

})();


},{}],6:[function(_dereq_,module,exports){
module.exports=".verso {\n  position: relative;\n  height: 100%;\n  display: none;\n  outline: 0;\n  overflow: hidden;\n  -webkit-box-sizing: border-box;\n  -moz-box-sizing: border-box;\n  box-sizing: border-box;\n}\n.verso[data-ready=\"true\"] {\n  display: block;\n}\n.verso *,\n.verso *:before,\n.verso *:after {\n  -webkit-box-sizing: inherit;\n  -moz-box-sizing: inherit;\n  box-sizing: inherit;\n}\n.verso__page {\n  position: absolute;\n  top: 0;\n  left: 0;\n  width: 100%;\n  height: 100%;\n}\n.verso__navigation {\n  position: absolute;\n  top: 50%;\n  z-index: 3;\n  margin-top: -25px;\n  width: 25px;\n  height: 50px;\n  line-height: 50px;\n  font-size: 22px;\n  font-weight: normal;\n  text-align: center;\n  overflow: hidden;\n  background-color: rgba(0,0,0,0.3);\n  color: #fff;\n  cursor: pointer;\n  -webkit-transition: opacity ease 300ms;\n  -moz-transition: opacity ease 300ms;\n  -o-transition: opacity ease 300ms;\n  -ms-transition: opacity ease 300ms;\n  transition: opacity ease 300ms;\n  opacity: 1;\n  -ms-filter: none;\n  filter: none;\n  -webkit-user-select: none;\n  -moz-user-select: none;\n  -ms-user-select: none;\n  user-select: none;\n}\n.verso__navigation:hover,\n.verso__navigation:focus {\n  background-color: rgba(0,0,0,0.6);\n}\n.verso__navigation:active {\n  background-color: rgba(0,0,0,0.8);\n}\n.verso__navigation[data-direction=\"previous\"] {\n  left: 0;\n}\n.verso__navigation[data-direction=\"next\"] {\n  right: 0;\n}\n@media (pointer: coarse), (max-width: 1000px) {\n  .verso__navigation {\n    display: none;\n  }\n}\n.verso__progress {\n  position: absolute;\n  left: 0;\n  right: 0;\n  bottom: 0;\n  z-index: 3;\n  height: 4px;\n}\n.verso-progress__inner {\n  position: relative;\n  width: 0%;\n  height: 4px;\n  background-color: rgba(0,0,0,0.3);\n  -webkit-transition: width 200ms ease-in;\n  -moz-transition: width 200ms ease-in;\n  -o-transition: width 200ms ease-in;\n  -ms-transition: width 200ms ease-in;\n  transition: width 200ms ease-in;\n}\n.verso__status {\n  position: absolute;\n  left: 50%;\n  bottom: 12px;\n  width: 90px;\n  margin-left: -45px;\n  z-index: 3;\n  background-color: rgba(0,0,0,0.3);\n  color: #fff;\n  text-align: center;\n  padding: 4px 0;\n  font-size: 14px;\n  font-family: inherit;\n  font-weight: 600;\n  -webkit-border-radius: 5px;\n  border-radius: 5px;\n}\n.verso[data-panning=\"true\"] > .verso__page {\n  -webkit-transition: none !important;\n  -moz-transition: none !important;\n  -o-transition: none !important;\n  -ms-transition: none !important;\n  transition: none !important;\n}\n.verso[data-transition=\"none\"] .verso-progress__inner {\n  -webkit-transition: none;\n  -moz-transition: none;\n  -o-transition: none;\n  -ms-transition: none;\n  transition: none;\n}\n.verso[data-transition=\"horizontal-slide\"] .verso__page {\n  -webkit-transition: -webkit-transform 200ms linear;\n  -moz-transition: -moz-transform 200ms linear;\n  -o-transition: -o-transform 200ms linear;\n  -ms-transition: -ms-transform 200ms linear;\n  transition: transform 200ms linear;\n}\n.verso[data-transition=\"horizontal-slide\"] .verso__page[data-state=\"before\"] {\n  -webkit-transform: translate3d(-200%, 0, 0);\n  -moz-transform: translate3d(-200%, 0, 0);\n  -o-transform: translate3d(-200%, 0, 0);\n  -ms-transform: translate3d(-200%, 0, 0);\n  transform: translate3d(-200%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] .verso__page[data-state=\"previous\"] {\n  -webkit-transform: translate3d(-100%, 0, 0);\n  -moz-transform: translate3d(-100%, 0, 0);\n  -o-transform: translate3d(-100%, 0, 0);\n  -ms-transform: translate3d(-100%, 0, 0);\n  transform: translate3d(-100%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] .verso__page[data-state=\"next\"] {\n  -webkit-transform: translate3d(100%, 0, 0);\n  -moz-transform: translate3d(100%, 0, 0);\n  -o-transform: translate3d(100%, 0, 0);\n  -ms-transform: translate3d(100%, 0, 0);\n  transform: translate3d(100%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] .verso__page[data-state=\"after\"] {\n  -webkit-transform: translate3d(200%, 0, 0);\n  -moz-transform: translate3d(200%, 0, 0);\n  -o-transform: translate3d(200%, 0, 0);\n  -ms-transform: translate3d(200%, 0, 0);\n  transform: translate3d(200%, 0, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page {\n  -webkit-transition: -webkit-transform 200ms linear;\n  -moz-transition: -moz-transform 200ms linear;\n  -o-transition: -o-transform 200ms linear;\n  -ms-transition: -ms-transform 200ms linear;\n  transition: transform 200ms linear;\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page[data-state=\"before\"] {\n  -webkit-transform: translate3d(0, -200%, 0);\n  -moz-transform: translate3d(0, -200%, 0);\n  -o-transform: translate3d(0, -200%, 0);\n  -ms-transform: translate3d(0, -200%, 0);\n  transform: translate3d(0, -200%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page[data-state=\"previous\"] {\n  -webkit-transform: translate3d(0, -100%, 0);\n  -moz-transform: translate3d(0, -100%, 0);\n  -o-transform: translate3d(0, -100%, 0);\n  -ms-transform: translate3d(0, -100%, 0);\n  transform: translate3d(0, -100%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page[data-state=\"next\"] {\n  -webkit-transform: translate3d(0, 100%, 0);\n  -moz-transform: translate3d(0, 100%, 0);\n  -o-transform: translate3d(0, 100%, 0);\n  -ms-transform: translate3d(0, 100%, 0);\n  transform: translate3d(0, 100%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page[data-state=\"after\"] {\n  -webkit-transform: translate3d(0, 200%, 0);\n  -moz-transform: translate3d(0, 200%, 0);\n  -o-transform: translate3d(0, 200%, 0);\n  -ms-transform: translate3d(0, 200%, 0);\n  transform: translate3d(0, 200%, 0);\n}\n.verso[data-transition=\"fade\"] > .verso__page {\n  -webkit-transition: opacity 300ms ease-in-out;\n  -moz-transition: opacity 300ms ease-in-out;\n  -o-transition: opacity 300ms ease-in-out;\n  -ms-transition: opacity 300ms ease-in-out;\n  transition: opacity 300ms ease-in-out;\n}\n.verso[data-transition=\"fade\"] > .verso__page[data-state=\"current\"] {\n  opacity: 1;\n  -ms-filter: none;\n  filter: none;\n}\n.verso[data-transition=\"fade\"] > .verso__page[data-state=\"previous\"],\n.verso[data-transition=\"fade\"] > .verso__page[data-state=\"before\"],\n.verso[data-transition=\"fade\"] > .verso__page[data-state=\"next\"],\n.verso[data-transition=\"fade\"] > .verso__page[data-state=\"after\"] {\n  opacity: 0;\n  -ms-filter: \"progid:DXImageTransform.Microsoft.Alpha(Opacity=0)\";\n  filter: alpha(opacity=0);\n}\n"
},{}],7:[function(_dereq_,module,exports){
var css, insertCss;

insertCss = _dereq_('insert-css');

css = _dereq_('./styl/index.styl');

insertCss(css);


},{"./styl/index.styl":6,"insert-css":10}],8:[function(_dereq_,module,exports){
var Interactivity, Navigation, Progress, Status, View;

View = _dereq_('./view');

Status = _dereq_('./status');

Navigation = _dereq_('./navigation');

Progress = _dereq_('./progress');

Interactivity = _dereq_('./interactivity');

module.exports = {
  View: View,
  Status: Status,
  Navigation: Navigation,
  Progress: Progress,
  Interactivity: Interactivity
};


},{"./interactivity":2,"./navigation":3,"./progress":4,"./status":5,"./view":9}],9:[function(_dereq_,module,exports){
var Events, Verso,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Events = _dereq_('./events');

module.exports = Verso = (function(superClass) {
  extend(Verso, superClass);

  Verso.prototype.defaults = {
    transition: 'horizontal-slide',
    pageIndex: 0
  };

  Verso.prototype.initialized = false;

  function Verso(el1, options) {
    var key, ref, ref1, value;
    this.el = el1;
    if (options == null) {
      options = {};
    }
    Verso.__super__.constructor.call(this);
    ref = this.defaults;
    for (key in ref) {
      value = ref[key];
      this[key] = (ref1 = options[key]) != null ? ref1 : value;
    }
    this.pages = Array.prototype.slice.call(this.el.querySelectorAll('.verso__page'), 0);
    return;
  }

  Verso.prototype.init = function() {
    if (this.initialized === true) {
      return;
    }
    this.trigger('beforeInit');
    this.updateState();
    this.el.dataset.transition = this.transition;
    this.el.dataset.ready = 'true';
    this.el.setAttribute('tabindex', -1);
    this.el.focus();
    this.initialized = true;
    this.trigger('init');
    return this;
  };

  Verso.prototype.go = function(pageIndex) {
    var from, to;
    if (isNaN(pageIndex) || pageIndex < 0 || pageIndex > this.getPageCount() - 1) {
      return;
    }
    from = this.pageIndex;
    to = pageIndex;
    this.trigger('beforeChange', from, to);
    this.pageIndex = to;
    this.updateState();
    this.trigger('change', from, to);
  };

  Verso.prototype.prev = function() {
    this.go(this.pageIndex - 1);
  };

  Verso.prototype.next = function() {
    this.go(this.pageIndex + 1);
  };

  Verso.prototype.getPageCount = function() {
    return this.pages.length;
  };

  Verso.prototype.updateState = function() {
    this.pages[this.pageIndex].dataset.state = 'current';
    this.pages[this.pageIndex].setAttribute('aria-hidden', false);
    if (this.pageIndex > 0) {
      this.pages[this.pageIndex - 1].dataset.state = 'previous';
      this.pages[this.pageIndex - 1].setAttribute('aria-hidden', true);
    }
    if (this.pageIndex + 1 < this.getPageCount()) {
      this.pages[this.pageIndex + 1].dataset.state = 'next';
      this.pages[this.pageIndex + 1].setAttribute('aria-hidden', true);
    }
    if (this.pageIndex > 1) {
      this.pages.slice(0, this.pageIndex - 1).forEach(function(el) {
        el.dataset.state = 'before';
        el.setAttribute('aria-hidden', true);
      });
    }
    if (this.pageIndex + 2 < this.getPageCount()) {
      this.pages.slice(this.pageIndex + 2).forEach(function(el) {
        el.dataset.state = 'after';
        el.setAttribute('aria-hidden', true);
      });
    }
  };

  return Verso;

})(Events);


},{"./events":1}],10:[function(_dereq_,module,exports){
var containers = []; // will store container HTMLElement references
var styleElements = []; // will store {prepend: HTMLElement, append: HTMLElement}

module.exports = function (css, options) {
    options = options || {};

    var position = options.prepend === true ? 'prepend' : 'append';
    var container = options.container !== undefined ? options.container : document.querySelector('head');
    var containerId = containers.indexOf(container);

    // first time we see this container, create the necessary entries
    if (containerId === -1) {
        containerId = containers.push(container) - 1;
        styleElements[containerId] = {};
    }

    // try to get the correponding container + position styleElement, create it otherwise
    var styleElement;

    if (styleElements[containerId] !== undefined && styleElements[containerId][position] !== undefined) {
        styleElement = styleElements[containerId][position];
    } else {
        styleElement = styleElements[containerId][position] = createStyleElement();

        if (position === 'prepend') {
            container.insertBefore(styleElement, container.childNodes[0]);
        } else {
            container.appendChild(styleElement);
        }
    }

    // actually add the stylesheet
    if (styleElement.styleSheet) {
        styleElement.styleSheet.cssText += css
    } else {
        styleElement.textContent += css;
    }

    return styleElement;
};

function createStyleElement() {
    var styleElement = document.createElement('style');
    styleElement.setAttribute('type', 'text/css');
    return styleElement;
}

},{}]},{},[8,7])(8)
});