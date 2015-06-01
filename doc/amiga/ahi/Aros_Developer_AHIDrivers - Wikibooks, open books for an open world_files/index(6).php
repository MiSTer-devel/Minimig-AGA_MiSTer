/* Per-book JavaScript. 
  * Maintained by [[User:Darklama]]
  * Use book-specific stylesheet and JavaScript.
  * You can ask an administrator to add or update a global book specific Stylesheet or JavaScript.
  */

(function( mw ) {
	var	ns = mw.config.get( 'wgNameSpaceNumber' ),
		user = mw.config.get( 'wgUserName', false ),
		book = mw.config.get( 'wgBookName' );

	if ( ns === 8 || mw.config.get( 'wgIsArticle' ) === false ) {
		return; 	/* Disable in MediaWiki space and when not viewing book material */
	} else if ( ns === 2 ) {
		/* Find correct book name in User space */
		book = mw.config.get( 'wgPageName' ).split( '/', 2 )[1];

		if ( book === 'per_book' ) {
			return; /* Disable within reserved spaces */
		}
	}

	/* global styling */
	importStylesheet( 'MediaWiki:Perbook/' + book + '.css' );
	importScript( 'MediaWiki:Perbook/' + book + '.js' );

	/* user styling */
	if ( user ) {
		importStylesheet( 'User:' + user + '/per_book/' + book + '.css' );
		importScript( 'User:' + user + '/per_book/' + book + '.js' );
	}
})( mediaWiki );