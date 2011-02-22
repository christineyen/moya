var moya = function() {
  var items = {};
  var init = function() {
    console.log('hallo');
  };

  return {
    init: init,
    items: items
  }
}();
$(document).ready(function() {
  moya.init();
});
