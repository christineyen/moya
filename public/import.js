// This JS is currently not hooked up anywhere.

var moya = function() {
  var items = [];
  var username = '';
  var password = '';

  var importIndividual = function(ct, doneCallback) {
    var next = items.pop();
    if (next == undefined) {
      doneCallback();
      return;
    }

    $.post('/migrate',
      { username: username,
        password: password,
        title: next.title,
        url: next.url },
      function(data) {
        ct++;
        if (data.code == '201') {
          $('.import-status').append('<div>Imported ' + ct + ': ' + next.title + '</div>');
          importIndividual(ct, doneCallback);
        } else {
          $('.import-status').append('<div class="import-error">Failed for ' + data.url + '. Aborting.</div>');
        }
      }
    );
  };

  var importInstapaper = function() {
    $('.import-loading').show();
    $('.import-status').append(items.length + ' items found. Importing...');
    importIndividual(0, function() {
      $('.import-status').append('Done!');
      $('.import-loading').hide();
    });

    return false;
  };

  var handleSubmit = function(e) {
    var form = $(e.target);
    
    url = form.attr('action');
    data = form.serializeArray();
    $('.import-status').text('');

    $.ajax({
      url: url,
      type: 'POST',
      data: data,
      success: function(data) {
        var err = false;
        for (key in data.errors) {
          err = true;
          $('.import-status').append('<div class="import-error">' + key + ': ' + data.errors[key] + '</div>');
        }

        if (!err) {
          items = data.items;
          username = data.username;
          password = data.password;
          importInstapaper();
        }
      }
    });
    return false;
  };
  var init = function() {
    $('a.import').click(importInstapaper);
    $('form.credentials').live('submit', handleSubmit);
  };

  return {
    init: init,
    items: items
  }
}();
$(document).ready(function() {
  moya.init();
});
