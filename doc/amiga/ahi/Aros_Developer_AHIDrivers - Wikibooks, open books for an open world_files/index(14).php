$(document).ready( function() {
	var	ns	= mw.config.get( 'wgNamespaceNumber' ),
		path	= '//commons.wikimedia.org/wiki/',
		file_ns = mw.config.get( 'wgFormattedNamespaces' )['6'],
		re	= RegExp('^\/\/upload\.wikimedia\.org\/wikipedia\/commons\/');

	if ( ns === 6 && !$('#ca-history').length && $('.sharedUploadNotice').length ) {
		var	title	= mw.util.wikiUrlencode( mw.config.get( 'wgTitle' ) ),
			lang	= mw.config.get( 'wgUserLanguage' );

		// Discussion link
		$('#ca-talk').filter('.new').find('a').attr('href', function(i, val) {
			return path + 'File_talk:' + title + '?uselang=' + lang;
		});

		// Edit link
		$( document.getElementById('ca-edit') || document.getElementById('ca-viewsource') )
			.find('a')
			.attr('href', function(i, val) {
				return path + 'File:' + title + '?uselang=' + lang + '&action=edit';
			});
	}

	$('a.image').attr('href', function(i, val) {
		if ( re.test( $(this).find('img').attr('src') ) ) {
			return val.replace('/wiki/' + file_ns + ':', path + 'File:');
		}
	});
});