Drupal = {
  behaviors: {},
  t: function(input) {
    return input;
  }
};

(function($) {
  $(function() {
    for (var script in Drupal.behaviors) {
      Drupal.behaviors[script].attach(document, {});
    }
    $('.styleguide-title__permalink').dblclick('doubleclick', function() {
    $title = $(this);
    href = $title[0].href;
    filename = getFilename(href).replace('section-', '');
    hash = $title[0].hash
      .replace('#kssref-', '')
      .replace(filename + '-', '');
    mdLink = 'Styleguide: [' + filename + '#' + hash + '](' + href + ')';
    $code = $('<pre />').html(mdLink);
    $title.after($code);
    });
  });
})(jQuery);


function getFilename(url) {
 if (url) {
   var m = url.toString().match(/.*\/(.+?)\./);
   if (m && m.length > 1) {
     return m[1];
   }
 }
 return "";
}