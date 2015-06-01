jQuery( function() {
	var pagename = mw.config.get( 'wgPageName' );
	// Main Page
	if ( pagename == 'Main_Page' || pagename == 'Talk:Main_Page' ) {
		$('#ca-nstab-main a').text( 'Main Page' );
	// Wikijunior
	} else if ( pagename == 'Wikijunior' || pagename == 'Talk:Wikijunior' ) {
		$('#ca-nstab-main a').text( 'Wikijunior' );
	// Cookbook:Table of Contents
	} else if ( pagename == 'Cookbook:Table_of_Contents' || pagename == 'Cookbook_talk:Table_of_Contents' ) {
		$('#ca-nstab-cookbook a').text( 'Cookbook' );
	}
});