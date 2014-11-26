var jsdom = require('jsdom').jsdom;

/**
 * Provides means to convert html strings into virtual documents.
 * @param {string} htmlstring
 * @return {Document}
 */
module.exports = function(htmlstring) {
  var doc = jsdom(htmlstring, {
    features: {
      FetchExternalResources: false,
      ProcessExternalResources: false
    }
  });
  return doc;
};
