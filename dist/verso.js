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
module.exports=".verso {\n  position: relative;\n  min-height: 100%;\n  margin: 0 auto;\n  overflow: hidden;\n  overflow-y: auto;\n  visibility: visible;\n}\n.verso > .verso__page {\n  absolute: top left;\n  right: 0;\n  bottom: 0;\n  z-index: 1;\n  background: #ffc0cb;\n}\n.verso > .verso--current {\n  z-index: 2;\n}\n.verso[data-transition=\"horizontal-slide\"] > .verso__page {\n  transition: transform 300ms ease-in-out;\n  position: absolute;\n  top: 0;\n  left: 0;\n}\n.verso[data-transition=\"horizontal-slide\"] > .verso--previous {\n  transform: translate3d(-100%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] > .verso--before {\n  transform: translate3d(-200%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] > .verso--next {\n  transform: translate3d(100%, 0, 0);\n}\n.verso[data-transition=\"horizontal-slide\"] > .verso--after {\n  transform: translate3d(200%, 0, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso__page {\n  transition: transform 300ms ease-in-out;\n  position: absolute;\n  top: 0;\n  left: 0;\n}\n.verso[data-transition=\"vertical-slide\"] > .verso--previous {\n  transform: translate3d(0, -100%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso--before {\n  transform: translate3d(0, -200%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso--next {\n  transform: translate3d(0, 100%, 0);\n}\n.verso[data-transition=\"vertical-slide\"] > .verso--after {\n  transform: translate3d(0, 200%, 0);\n}\n"
},{}],3:[function(_dereq_,module,exports){
var css, insertCss;

insertCss = _dereq_('insert-css');

css = _dereq_('./styl/index.styl');

insertCss(css);


},{"./styl/index.styl":2,"insert-css":5}],4:[function(_dereq_,module,exports){
var Events, Verso,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Events = _dereq_('./events');

module.exports = Verso = (function(superClass) {
  extend(Verso, superClass);

  Verso.prototype.defaults = {
    keysPrev: [8, 33, 37, 38],
    keysNext: [13, 32, 34, 39, 40],
    transition: 'horizontal-slide',
    swipeDirection: 'horizontal',
    swipeTolerance: 60
  };

  function Verso(el, options) {
    var key, ref, ref1, value;
    this.el = el;
    if (options == null) {
      options = {};
    }
    ref = this.defaults;
    for (key in ref) {
      value = ref[key];
      this[key] = (ref1 = options[key]) != null ? ref1 : value;
    }
    this.pages = this.el.querySelectorAll('.verso__page');
    this.el.dataset.transition = this.transition;
    return;
  }

  Verso.prototype.init = function() {};

  return Verso;

})(Events);


},{"./events":1}],5:[function(_dereq_,module,exports){
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

},{}]},{},[4,3])(4)
});