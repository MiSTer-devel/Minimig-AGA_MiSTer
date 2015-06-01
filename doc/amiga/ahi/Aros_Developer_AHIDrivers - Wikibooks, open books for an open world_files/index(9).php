// Force short review box to be on its own line.

$(document).ready( function($) {
  $('.flaggedrevs_short').wrap('<div style="display:block; clear:both; height:20px; line-height:18px; margin:5px;" />');
});