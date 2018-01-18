
// render_stickers_pdf
// 04/04/2015
// 06/03/2016 - updated to handle API get vs passing in JSON file and directly uploading to S3
// Charles Mastin
// This beaut uses node pdfkit to render pages of sticker sheets (3 per page, 1 sheet == 1 lifesquare)
// If a lifesquare is unassigned, no biggie, we still render everything else
// This was created as a translation of outgoing Adobe Illustrator jsx scripts
// Unsure of memory constraints for large batches
// TODO: spin off utils into a module and require them?
// TODO: write a test that renders the sample data (which should be depersonalized)
// TODO: tweak type metrics and layout for future product/org names

var args = process.argv.slice(2);

var PDFDocument = require('pdfkit');
var fs = require('fs');
var yaml = require('js-yaml');
// var http = require('http');
// var https = require('https');
var stream = require('stream');
var AWS = require('aws-sdk');
var request = require('request'); 
var s3Stream;

var StickerRenderer = {

  renderSMSInfo: true,

  colors: {
    red: '#c4262e',
    black: '#000000',
    white: '#ffffff',
    gray: '#E6E7E8',
    darkgray: '#9F9F9F',
    debug: '#00bbff',
    darkblue: '#1e2327'
  },

  paths: {
    badge_large: 'M0,0h18.994c6.3,0,12.6,6.3,12.6,12.6v97.891H12.6c-6.3,0-12.6-6.3-12.6-12.6V0z',
    badge_medium: 'M0,0h10.037c3.149,0,6.3,3.15,6.3,6.3v49.486H6.3c-3.149,0-6.3-3.15-6.3-6.3V0z',
    badge_small: 'M0,0h7.797c2.363,0,4.725,2.362,4.725,4.725v37.384H4.725C2.362,42.109,0,39.747,0,37.384V0z',
    mailer: 'M9,44.64c-4.97,0-9-4.029-9-9V9c0-4.97,4.03-9,9-9h176.4c4.971,0,9,4.03,9,9v26.64c0,4.971-4.029,9-9,9H9z'
  },

  metrics: {
    sheetHeight: 264,// half inch margin top + bottom @ 72 264,
    qrOffset: 0.071,  // Offset of QR code from top-left corner (fraction of sticker),
    logo_x: 0.057, // offset, fraction of w
    logo_y: 0.777, // 0.772 offset, fraction of w
    ls_small: {
      size: 0.75 * 72,
      name: 'small',
      x: 60,
      y: 0.265 * 72, //0.25
      qr_unit: 1.39,
      logo_size: 10,
      id_x: -39,
      id_y: 45,
      badge_x: 42,
      badge_y: -1,
      id_origin_x: 50,
      id_origin_y: 0,
      id_size: 5.47,
      org_size: 5.625,
      tag_size: 3.75
    },
    ls_medium: {
      size: 1.0 * 72,
      name: 'medium',
      x: 80,
      y: 0.265 * 72,
      qr_unit: 1.86,
      logo_size: 13.35,
      id_x: -52,
      id_y: 61,
      badge_x: 57,
      badge_y: -1,
      id_origin_x: 70,
      id_origin_y: 0,
      id_size: 7.3,
      org_size: 7.5,
      tag_size: 5
    },
    ls_large: {
      size: 2.0 * 72,
      name: 'large',
      x: 200,
      y: 0.265 * 72,
      qr_unit: 3.72,
      logo_size: 26.7,
      id_x: -104,
      id_y: 122,
      badge_x: 114,
      badge_y: -2,
      id_origin_x: 140,
      id_origin_y: 0,
      id_size: 14.6,
      org_size: 13,
      tag_size: 10
    }
  },

  // load up your data son bun huns
  init: function(config){
    this.config = config;

    // read auth from the filesystem son yea son yea yea
    try {
      var doc = yaml.safeLoad(fs.readFileSync('config/credentials-local.yml', 'utf8'));
      // write the necessary bits to the config
      this.config.aws_access_key = doc['s3_picp']['access_key_id'];
      this.config.aws_secret_key = doc['s3_picp']['secret_access_key'];
      this.config.s3_bucket = doc['s3_picp']['bucket_name'];
    } catch (e) {
      console.error(e);
      return;
    }

    // Make sure AWS credentials are loaded using one of the following techniques 
    AWS.config.update({accessKeyId: config.aws_access_key, secretAccessKey: config.aws_secret_key});
    s3Stream = require('s3-upload-stream')(new AWS.S3());

    var scope = this;
    var request_options = {
      url: config.data_uri,
      headers: {
        'User-Agent': 'request',
        'X-Account-Email': doc['nodeapiauth']['email'],
        'X-Account-Token': doc['nodeapiauth']['token']
      }
    };

    function callback(error, response, body) {
      if (!error && response.statusCode == 200) {
        scope.data = JSON.parse(body);
        scope.renderDocument();
      } else {
        console.error(response);
      }
    }

    request(request_options, callback);
  },

  renderDocument: function(){
    // bake the document
    this.doc = new PDFDocument({margin: 0});//36

    var upload = s3Stream.upload({
      Bucket: this.config.s3_bucket,
      Key: this.config.s3_key,
      StorageClass: "REDUCED_REDUNDANCY",
      ContentType: 'binary/octet-stream'
    });

    this.doc.pipe(upload);

    // break apart the flat list into pages
    var pages = chunk(this.data.lifesquares, 3);

    for(var i=0;i<pages.length;i++){
      if(i > 0){
        this.doc.addPage();
      }
      this.renderPage(pages[i]);
    }

    // close it up
    this.doc.end();
  },

  renderPage: function(data){
    // hmm, margins and such, TBD
    this.pageoffset = {};
    for(var i=0;i<data.length;i++){
      this.doc.save();
      this.renderSheet(data[i], i);
      this.doc.restore();
    }
  },

  renderSheet: function(data, index){
    var matrix = this.parseQRCode(data.qr);
    // var xPos = 0;
    // 4 small
    var offsets = [0.2500, 1.1666, 2.0833, 3.0000];
    for(var i=0;i<4;i++){
      this.renderLifesquare(data, matrix, data.lifesquare, this.metrics.ls_small, {
        x: offsets[i] * 72,
        y: (index * this.metrics.sheetHeight) + 0.25 * 72
      },i);
      // xPos += this.metrics.ls_small.x;
    }

    offsets = [3.9166, 5.0833];
    // 2 medium
    for(var i=0;i<2;i++){
      this.renderLifesquare(data, matrix, data.lifesquare, this.metrics.ls_medium, {
        x: offsets[i] * 72,
        y: (index * this.metrics.sheetHeight) + 0.25 * 72
      },4+i);
      // xPos += this.metrics.ls_medium.x
      // (this.metrics.ls_small.x * 4) + (this.metrics.ls_medium.x * i)
    }

    offests = [6.2500];
    // 1 large
    this.renderLifesquare(data, matrix, data.lifesquare, this.metrics.ls_large, {
      x: 6.2500 * 72,
      y: (index * this.metrics.sheetHeight) + 0.25 * 72
    }, 6);

    this.doc.save();

    // now we froze the transforms, lol, ok ok ok ok, still a bit hard to understand

    // name / address
    //dpi * (addressX),
    //dpi * (pageHeight - addressY - offset)
    //var addressX = 1.0;  // x-offset of address on sheet
    //var addressY = 2.4;
    if(data.name != undefined && data.name != ''){
      this.doc
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
        .fontSize(12)
        .fillColor(this.colors.black)
        .text(data.name + '\n' + data.address, 1 * 72, (index * this.metrics.sheetHeight) + (2.4 * 72));

      // mailer badge
      this.doc
        .translate(400, (index * this.metrics.sheetHeight) + 200)
        .path(this.paths.mailer)
        .fill(this.colors.gray);

      // misc
      var text = 'Stickers belong to:';
      if(data.reprint != undefined && data.reprint){
        text = 'REPRINTED stickers belong to:';
      }
      this.doc
        // .translate(0, (index * this.metrics.sheetHeight))
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
        .fontSize(10)
        .fillColor(this.colors.black)
        .text(text, 8, -13);


      // name
      this.doc
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue Bold')
        .fontSize(12)
        .fillColor(this.colors.black)
        .text(data.name, 8, 8);

      // dob
      this.doc
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
        .fontSize(12)
        .fillColor(this.colors.black)
        .text('born ' + data.dob, 8, 23);

      // reprint

      if(data.reprint != undefined && data.reprint){
        this.doc
          // .translate(0, (index * this.metrics.sheetHeight))
          .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue Bold')
          .fontSize(10)
          .fillColor(this.colors.black)
          .text('REPRINTED', -328, -59);
      }
    }

    if(data.instructions != undefined && data.instructions.length > 0){
      // this.doc.save();

      // this.doc
      //   .translate(20, (index * this.metrics.sheetHeight) + 120);

      // needs to be a certain width to fit the space though

      this.doc
        // .translate(0, (index * this.metrics.sheetHeight))
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
        .fontSize(10)
        .fillColor(this.colors.darkblue)
        .text(data.instructions, 20, (index * this.metrics.sheetHeight) + 125, { width:275, align: 'left', lineBreak: true});

        // this.doc.restore();
    }

    // weburl, social, etcC

    this.doc.restore();
  },

  renderLifesquare: function(data, matrix, id, metrics, offset, index){
    // the actual sticker that comes off, the QR code + number
    // code
    this.renderQRCode(matrix, metrics, offset);    
    this.doc.save();

    var smsoffset = metrics.tag_size * 0.8;

    if(data.org == undefined || data.org == 'HealthNotifier'){
      // logo
      // TODO: get the actual logo typeface
      // TODO: use a vector shape instead of type here and do scaling
      this.doc.font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue Bold')

      var y = offset.y + metrics.size * this.metrics.logo_y;
      var logoFontSize = metrics.logo_size;
      if(this.renderSMSInfo){
        y -= metrics.tag_size * 0.4; // custom for dis one
        logoFontSize = metrics.logo_size * 0.8;
      }

      this.doc
        // .translate(offset.x, offset.y)
        .fontSize(logoFontSize)
        .fillColor(this.colors.darkblue)
        .text('HealthNotifier', offset.x + metrics.size * this.metrics.logo_x, y);
    }
    if(data.org != undefined && data.org != '' && data.org != 'HealthNotifier'){
      // the org
      var y = offset.y + metrics.size * this.metrics.logo_y;
      if(this.renderSMSInfo){
        y -= smsoffset;
        if(metrics.name == 'small'){
          y -= metrics.tag_size * 0.125;
        }
      }
      this.doc
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue Bold')
        .fontSize(metrics.org_size)
        .fillColor(this.colors.darkblue)
        .text("HealthNotifier", offset.x + metrics.size * this.metrics.logo_x, y);

      // powered by lifesquare
      var y = offset.y + metrics.org_size + 1 + metrics.size * this.metrics.logo_y;
      if(this.renderSMSInfo){
        y -= smsoffset;
        if(metrics.name == 'medium'){
          y -= metrics.tag_size * 0.125;
        }
        if(metrics.name == 'small'){
          y -= metrics.tag_size * 0.4;
        }
      }
      this.doc
        .font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
        .fontSize(metrics.tag_size)
        .fillColor(this.colors.darkblue)
        .text('Sponsored by ' + data.org, offset.x + metrics.size * this.metrics.logo_x, y);
    }

    // badge
    this.doc.save();
    this.doc
     .translate(offset.x + metrics.badge_x, offset.y + metrics.badge_y)
     .path(this.paths['badge_'+metrics.name])
     .fill(this.colors.red);
    this.doc.restore();

    // lifesquare id (member number)
    this.doc.save();
    // TODO: get a monospace open sourced alternative here
    this.doc.font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
    this.doc
      .translate(offset.x, offset.y)
      .rotate(-90, {origin: [0, 0]})
      .fontSize(metrics.id_size)
      .fillColor(this.colors.white)
      .text(id.charAt(0) + id.charAt(1) + id.charAt(2) + " " +
        id.charAt(3) + id.charAt(4) + id.charAt(5) + " " +
        id.charAt(6) + id.charAt(7) + id.charAt(8), metrics.id_x, metrics.id_y
      );
    this.doc.restore();
    this.doc.rotate(90);
    this.doc.restore();

    if(this.renderSMSInfo){
      // SMS API info son
      var SMS_METRICS = {
        x: offset.x + (metrics.size * this.metrics.logo_x),
        y: offset.y + ((metrics.org_size + 1 + metrics.size) * this.metrics.logo_y) + (metrics.tag_size * 1.4)// one line height son
      }

      SMS_METRICS.y -= smsoffset;

      //SMS_METRICS.x = offset.x + (metrics.size * this.metrics.logo_x);
      //SMS_METRICS.y = offset.y;

      if(data.org == undefined){
        // default 1 liner LIFESQUARE son
      }
      if(data.org != undefined && data.org != ''){
        // 2 liner with powered by
      }

      if(metrics.name == 'medium'){
        SMS_METRICS.y -= metrics.tag_size * 0.125;
      }
      if(metrics.name == 'small'){
        SMS_METRICS.y -= metrics.tag_size * 0.4;
      }

      // bump based on dat tag doe
      
      this.doc.save();
      this.doc.font('app/assets/fonts/HelveticaNeue/HelveticaNeue.dfont', 'Helvetica Neue')
      this.doc
        //.translate(SMS_METRICS.x, SMS_METRICS.y)
        // .rotate(-90, {origin: [0, 0]})
        .fontSize(metrics.tag_size)
        .fillColor(this.colors.darkgray)
        .text('TEXT 415.523.9118 FOR INFO', SMS_METRICS.x, SMS_METRICS.y);
      this.doc.restore();
    }
  },

  renderQRCode: function(matrix, metrics, offset){
    var qryoffset = this.metrics.qrOffset;
    if(metrics.name == 'large'){
      qryoffset += 0.05;
    }
    if(metrics.name == 'small'){
      qryoffset -= 0.025;
    }
    var size = metrics.qr_unit;
    // Just the QR Code
    this.doc.fillColor(this.colors.red);
    // this.doc.roundedRect(offset.x + (this.metrics.qrOffset * metrics.size), offset.y + (qryoffset * 72), 25*size, 25*size, 2).fill();
    // return;
    var x = offset.x + (this.metrics.qrOffset * metrics.size);
    // var y = offset.y;

    for(var i=0;i<25;i++){
      var y = offset.y + (qryoffset * 72);
      for(var j=0;j<25;j++){
        if(getArray2dCW(matrix, j, i*2) == '#'){
          this.doc.roundedRect(x, y, size, size, 0).fill();
        }
        y += size;
      }
      x += size;
    }
  },

  parseQRCode: function(data){
    var qrData = data.split('\n');
    var matrix = [];
    for(var i=0;i<qrData.length;i++){
      var line = [];
      for(var j=0;j<qrData[i].length;j++){
        line.push(qrData[i].charAt(j));
      }
      matrix.push(line);
    }
    return matrix;
  }

};

// Launch that puppy too lazy to see how to write a constructor
StickerRenderer.init({
  data_uri: args[0],
  s3_key: args[1]
});

// Utility Methods, move them elsewhere?
function getArray2dCW(a, x, y) {
  // http://stackoverflow.com/a/26374543
  var t = x;
  x = y;
  y = a.length - t - 1;
  return a[y][x];
}

function chunk (arr, len) {
  // http://stackoverflow.com/questions/8495687/split-array-into-chunks
  var chunks = [],
      i = 0,
      n = arr.length;
  while (i < n) {
    chunks.push(arr.slice(i, i += len));
  }
  return chunks;
}
