var derequire = require('browserify-derequire');
var browserify = require('browserify');
var options = {
    transition: (process.argv[2] || process.env.TRANSITION || '').split(','),
    minify: process.env.MINIFY ? true : false
};
var entries = ['./lib/verso.coffee'];
var brOptions = {
    entries: entries,
    extensions: ['.coffee'],
    standalone: 'Verso',
    plugin: [derequire]
};

switch (options.transition) {
    case 'horizontal-slide':
        entries.push('./lib/styl/transitions/horizontal-slide.styl');
        break;
    case 'vertical-slide':
        entries.push('./lib/styl/transitions/vertical-slide.styl');
        break;
}

browserify(brOptions)
    .transform('coffeeify')
    .transform({ global: true }, 'stylusify')
    .bundle()
    .pipe(process.stdout);
