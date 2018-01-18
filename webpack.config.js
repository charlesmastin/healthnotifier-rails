var path = require('path');
var webpack = require('webpack');

module.exports = {
  entry: [
    //'react-hot-loader/patch',
    //'webpack-dev-server/client?http://0.0.0.0:3001',
    //'webpack/hot/only-dev-server',
    './app/assets/javascripts/main-careplan.js',
  ],
  output: {
    path: './app/assets/javascripts',
    filename: 'careplan-bundle.js'
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin()
  ],
  devServer: {
    colors: true,
    historyApiFallback: true,
    inline: false,
    port: 3001,
    hot: false
  },
  module: {
    loaders: [{
      test: /\.js$/,
      loader: 'babel-loader',
      exclude: /node_modules/,
      query: {
        "presets": ["es2015", "react"],
        //"plugins": ["react-hot-loader/babel"]
      }
      //include: path.join(__dirname, 'src')
    }]
  },
  
};