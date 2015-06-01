// Move icons and navigation to top of content area, which should place them right below the page title

mw.hook('wikipage.content').add(function($where) {
	var $content = mw.util.$content, $what = $where.find('.topicon').css('display', 'inline');
	
	if ( $what.length ) {
		$content.find(':header').eq(0).wrapInner('<span />').append( $('<span id="page-status" />').append($what) );
	}
	
	$what = $where.find('#top-navigation').remove().slice(0,1).addClass('subpages');
	if ( $what.length ) { $content.find('.subpages').eq(0).replaceWith($what); }
	
	$what = $where.find('#bottom-navigation').remove().slice(0,1);
	if ( $what.length ) { $where.append($what); }
});