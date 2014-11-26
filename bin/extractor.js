require('../../../library/closure/goog/bootstrap/nodejs.js');
// Dependencies for custom namespace.
require('../../pstj/deps.js');

// Closure library custom namespace require.
goog.nodeGlobalRequire('../../pstj/ds/jstype/extrator.js');

var jsdom = require('jsdom').jsdom;
var request = require('request');
var documentMaker = require('../lib/document.js');
var fs = require('fs');

var Defaults = {
  DOMAIN: 'https://developers.google.com',
  URL: '/cast/docs/reference/chrome/',
  SELECTOR: 'a[href="/cast/docs/reference/chrome"]'
};

var url = (process.argv[2]) ? process.argv[2] :
    Defaults.URL;

var _len = 0;
var result = [];

request(Defaults.DOMAIN + Defaults.URL, function(err, resp, body) {
  if (err) {
    throw err;
  }
  if (resp.statusCode == 200) {
    onInitialUrlLoaded(body);
  } else {
    throw new Error('Status code: ' + resp.statusCode);
  }
});


function onInitialUrlLoaded(htmlstring) {
  var doc = documentMaker(htmlstring);
  var list = pstj.ds.jstype.Extractor.getLinkList(doc, Defaults.SELECTOR);
  _len = list.length + 1;
  loadHandler(null, {statusCode: 200}, htmlstring);
  goog.array.forEach(list, function(url) {
    console.log('Requesting: ' + Defaults.DOMAIN + url);
    request(Defaults.DOMAIN + url, loadHandler);
  });
}


function loadHandler(err, resp, body) {
  // console.log('Received response:', resp.request.uri.path);
  if (err) {
    throw err;
    process.exit(1);
  }

  if (resp.statusCode != 200) {
    console.log('Error code: ' + resp.statusCode);
  }

  var doc = documentMaker(body);
  var extractor = new pstj.ds.jstype.Extractor();
  extractor.setDocument(doc);
  extractor.extract();

  result.push(extractor.toString());

  console.log(_len, result.length);
  if (result.length == _len) {
    put();
  }
}

function put() {
  fs.writeFileSync('out.js', result.join('\n\n\n'));
}