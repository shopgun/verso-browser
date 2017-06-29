const coffee = require('coffee-script');

module.exports = {
    process(src, path) {
        if (path.endsWith('.coffee')) {
            const js = coffee.compile(src, { bare: true });

            return js;
        }

        return src;
    }
};
