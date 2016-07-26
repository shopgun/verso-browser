var derequire = require('browserify-derequire');
var browserify = require('browserify');
var options = {
    minify: process.env.MINIFY ? true : false
};
var entries = [
    './lib/verso.coffee',
    './lib/stylesheets.coffee'
];
var brOptions = {
    entries: entries,
    extensions: ['.coffee'],
    standalone: 'Verso',
    plugin: [derequire]
};

browserify(brOptions)
    .transform('coffeeify')
    .transform({ global: true }, 'stylusify')
    .bundle()
    .pipe(process.stdout);
