$.fn.slideshow = ( function() {
	return this.each( function() {
		var $ss = $(this), $sl = $ss.children( '.slide' ), $actions;

		if ( $sl.length < 2 ) {
			return;
		}

		$sl.slice(1).hide();
		$actions = $('<div class="slide-actions"><span class="slide-prev"></span><span class="slide-next"></span></div>');
		$ss.data( 'slides', { 'at': 0, 'total': $sl.length }).append( $actions ).click( function(e) {
			var $where = $( e.target ), $ss, $sl, data;

			if ( $where.is( '.slide-prev' ) ) {
				e.stopPropagation();
				$ss = $(this); $sl = $ss.children( '.slide' ); data = $ss.data( 'slides' );
				if ( data.at > 0 ) {
					--data.at;
					$sl.eq( data.at + 1).fadeOut(1000).end().eq( data.at ).delay(1000).fadeIn(1000);
					$ss.data( 'slides', data );
				}
			} else if ( $where.is( '.slide-next' ) ) {
				e.stopPropagation();
				$ss = $(this); $sl = $ss.children( '.slide' ); data = $ss.data( 'slides' );
				if ( data.at < data.total - 1 ) {
					++data.at;
					$sl.eq( data.at - 1).fadeOut(1000).end().eq( data.at ).delay(1000).fadeIn(1000);
					$ss.data( 'slides', data );
				}
			}
		});
	});
});

$(document).ready( function() { $( '.slides' ).slideshow(); } );