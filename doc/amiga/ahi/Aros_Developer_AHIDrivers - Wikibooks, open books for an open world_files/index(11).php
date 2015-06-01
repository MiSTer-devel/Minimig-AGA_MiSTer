/*
 * Load CSS and JS files temporarily through URL.
 * &use=File1.css|File2.css|File3.js
 */
(function () {
	var files = mw.util.getParamValue( 'use' ), user, FileRE, what, u, f, l;
	if ( !files ) {
		return;
	}
	files = files.split('|');
	user = $.escapeRE( mw.config.get( 'wgUserName', '' ) );
	FileRE = new RegExp( '^(?:MediaWiki:' + ( user ? '|User:' + user + '/' : '' ) + ').*\\.(js|css)$' );
	for ( u = 0, f = $.trim( files[u] ), l = files.length; u < l; f = $.trim( files[++u] ) ) {
		what = FileRE.exec(f);
		if ( what == null ) {
			continue;
		}
		switch ( what[1] ) {
			case 'js': importScript(f); break;
			case 'css': importStylesheet(f); break;
		}
	}
}());