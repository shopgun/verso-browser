# Verso [![Build Status](https://travis-ci.org/shopgun/verso-browser.svg?branch=develop)](https://travis-ci.org/shopgun/verso-browser)

A multi-paged viewer for browsers. See `kitchensink/example1.html` for how it works.

# Changelog
## Version ?.?.?
* Fixed bug where arguments were not being passed to external event handlers.

## Version 1.0.28
* Use new mainFields option for rollup-plugin-node-resolve.
* Internal refactor for ES6 modules.
* Skip some unnecessary polyfill bundling.
* Add warnings for a number of common usage errors.

## Version 1.0.27
* Update dependencies.

## Version 1.0.26
* Fix bug where doing `viewer.start(); viewer.destroy(); viewer.start();` would break the viewer.

## Version 1.0.25
* Revert to core-js 2 for now

## Version 1.0.24
* Fix duplicate dev/runtime dependency on rollup-terser-plugin

## Version 1.0.23
* Update dependencies
* Fix missing core-js runtime dependency