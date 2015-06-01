(function($) {
	if ( $.inArray( mw.config.get( 'wgAction' ), ['edit','submit']) === -1 || $.fn.wikiEditor === undefined ) {
		return;
	}

	if ( window.mwCustomEditButtons === undefined ) {
		window.mwCustomEditButtons = [];
	}

	$(document).ready( function() {
		var $tb = $('#wpTextbox1');
		$.each( mwCustomEditButtons, function(i) {
			var wikiOptions = { section: 'main', group: 'insert', tools: {}}, tool = this;
			wikiOptions.tools[ tool.name || 'mw-custom-edit-button-' + (i+1) ] = {
				label: tool.speedTip,
				type: 'button',
				icon: tool.imageFile,
				action: {
					type: 'callback',
					execute: function() {
						$tb.textSelection( 'encapsulateSelection', {
							pre: tool.tagOpen || '',
							peri: tool.sampleText || '',
							post: tool.tagClose || ''
						});
						if ( $.isFunction( tool.callbackFunct ) ) {
							tool.callbackFunct.call( window );
						}
					}
				}
			}
			$tb.wikiEditor( 'addToToolbar', wikiOptions );
		});
	});
})( jQuery );