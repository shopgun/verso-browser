import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';
import {terser} from 'rollup-plugin-terser';
import path from 'path';
import babel from 'rollup-plugin-babel';
import globals from 'rollup-plugin-node-globals';

var input = path.join(__dirname, 'lib', 'verso.js');

var outputs = {
    // Exclusive bundles(external `require`s untouched), for node, webpack etc.
    CJS: path.join(__dirname, 'dist', 'verso.cjs.js'), // CommonJS
    ES: path.join(__dirname, 'dist', 'verso.es.js'), // ES Module
    // Inclusive bundles(external `require`s resolved), for browsers etc.
    UMD: path.join(__dirname, 'dist', 'verso.js'),
    UMDMin: path.join(__dirname, 'dist', 'verso.min.js')
};

const getBabelPlugin = () =>
    babel({
        exclude: ['node_modules/**'],
        extensions: ['.js', '.jsx', '.es6', '.es', '.mjs']
    });

let configs = [
    {
        input,
        output: {
            file: outputs.CJS,
            format: 'cjs'
        },
        plugins: [
            commonjs({
                extensions: ['.js']
            }),
            getBabelPlugin()
        ]
    },
    {
        input,
        output: {
            file: outputs.ES,
            format: 'es'
        },
        plugins: [
            commonjs({
                extensions: ['.js']
            }),
            getBabelPlugin()
        ]
    },
    {
        input,
        output: {
            file: outputs.UMD,
            format: 'umd',
            name: 'Verso'
        },
        plugins: [
            resolve({
                mainFields: ['jsnext:main', 'main'],
                browser: true,
                preferBuiltins: false
            }),
            commonjs({
                extensions: ['.js']
            }),
            globals(),
            getBabelPlugin()
        ]
    },
    {
        input,
        output: {
            file: outputs.UMDMin,
            format: 'umd',
            name: 'Verso'
        },
        plugins: [
            resolve({
                mainFields: ['jsnext:main', 'main'],
                browser: true,
                preferBuiltins: false
            }),
            commonjs({
                extensions: ['.js']
            }),
            globals(),
            getBabelPlugin(),
            terser()
        ]
    }
];

// Only output unminified browser bundle in development mode
if (process.env.NODE_ENV === 'development') configs = [configs[2]];

export default configs;
