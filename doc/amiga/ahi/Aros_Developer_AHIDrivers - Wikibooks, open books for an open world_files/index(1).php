// This page is for keeping track of JavaScript that may no longer be useful/functional someday.

mw.log.deprecate(window, 'addLoadEvent', function(fn) {
	jQuery.ready(fn);
}, 'Use jQuery.ready instead.' );

window.import_script = function(name) {
	mw.loader.load(
		mw.config.get('wgServer')
		+ mw.config.get('wgScript')
		+ '?title=' + mw.util.wikiUrlencode(name)
		+ '&action=raw&ctype=text/javascript'
	);
};

window.import_style = function(name) {
	mw.loader.load(
		mw.config.get('wgServer')
		+ mw.config.get('wgScript')
		+ '?title=' + mw.util.wikiUrlencode(name)
		+ '&action=raw&ctype=text/css'
	);
};

// Removes the default no-license option for uploads.
function remove_no_license()
{
	if ( mw.config.get('wgCanonicalSpecialPageName') !== 'Upload' )
		return;
	$('#wpLicense').find('option').eq(0).remove();
}

$(document).ready(remove_no_license);