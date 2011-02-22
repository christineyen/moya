// This JS is currently not hooked up anywhere.
//
// I'd LOVE to do something where we separate the RIL / Instapaper forms, and
// when we get their IP credentials, we store them in the JS locally and use
// Instapaper's JSONP functionality to recurse until all of the items we want to
// load are left.
//
// That... is a todo for the next time I get itchy fingers.

var moya = function() {
  var items = [];

  var importIndividual = function(ct, doneCallback) {
    var next = window.items.pop();
    if (next == undefined) {
      doneCallback();
      return;
    }

    $.post('/migrate', { title: next.title, url: next.url }, function() {
      ct++;
      $('.import-status').append('Imported ' + ct + ': ' + next.title);
      importIndividual(ct, doneCallback);
    });
  };

  var importInstapaper = function() {
    $('.import-loading').show();
    importIndividual(0, function() {
      $('.import-status').append('Done!');
      $('.import-loading').hide();
    });

    return false;
  };
  var init = function() {
    $('a.import').click(importInstapaper);
  };

  return {
    init: init,
    items: items
  }
}();
$(document).ready(function() {
  moya.init();
});
