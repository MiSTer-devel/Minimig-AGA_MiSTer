function change_displaytitle()
{
	var text = $("#displaytitle").attr('title'), what;

	if ( text ) {
		what = $("#ca-nstab-" + ( mw.config.get('wgCanonicalNamespace').toLowerCase() || 'main' ) );
		what.find('a').text(text);
	}
}
 
$(document).ready(change_displaytitle);