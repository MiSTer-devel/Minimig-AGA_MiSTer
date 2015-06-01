// Navigate Tabs. Allows for lots of information to be displayed on a page in a more compact form.
// Maintained by [[User:Darklama]]
 
function Navigate_Tabs()
{
	function clicked_tab( e )
	{
		var $target = $( e.target ), id = e.target.hash;

		if ( !$target.is( 'a' ) || !id ) {
			return true;
		}

		$target = $(this).siblings( id );

		if ( !$target.hasClass( 'contents' ) || !$target.parent().hasClass( 'navtabs' ) ) {
			return true;
		}

		e.preventDefault();

		$target.parent().children( '.tabs' ).find( 'a' ).each( function() {
			if ( this.hash !== id ) {
				$(this).parent().addClass( 'inactive' ).removeClass( 'selected' );
			} else {
				$(this).parent().addClass( 'selected' ).removeClass( 'inactive' );
			}
		} );

		$target.parent().children( '.contents' ).hide();
		$target.show();
	}

	mw.util.$content.find('.navtabs').each( function() {
		var $this = $(this), $p = $this.children( 'p' ), $tabs, $any;

		// remove any surrounding paragraph first
		$p.has( '.tabs' ).before( $p.children( '.tabs' ) ).remove();

		// deal with clicks, and show default
		$tabs = $this.children( '.tabs' ).click( clicked_tab );
		$any = $tabs.children( '.selected' ).find('a[href^="#"]').click();

		if ( !$any.length ) {
			$tabs.children(':first-child').find('a[href^="#"]').click();
		}
	} );
}
 
$(document).ready(Navigate_Tabs);