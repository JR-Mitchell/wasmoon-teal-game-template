const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const path = require('path');

/** @type {import('webpack').Configuration} */
const config = {
    entry: './src/index.js',
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'app.js'
    },
    resolve: {
        fallback: {
            path: false,
            fs: false,
            child_process: false,
            crypto: false,
            url: false,
            module: false
        }
    },
    module: {
        rules: [
            {
                test: /\.(png|wasm)$/,
                type: 'asset/resource',
            },
            {
                test: /\.lua$/,
                type: 'asset/source'
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: 'src/index.html'
        }),
        new CopyWebpackPlugin({
            patterns: [
                { from: 'src/assets/server', to: '../server' },
            ],
        }),
    ],
    experiments: {
        asyncWebAssembly: true
    }
};

module.exports = config;
