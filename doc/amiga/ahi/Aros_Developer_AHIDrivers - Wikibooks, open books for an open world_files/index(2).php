(function(mw, $) {
	window.add_toolbox_link = function(action, name, id) {
		var $tools = $('#p-tb ul');
		if ( !$tools.length ) return;
		if (typeof action === "string") {
			$tools.append('<li id="t-' + (id || name) + '"><a href="' + action + '">' + name + '</a></li>');
		} else if (typeof action === "function") {
			$('<li id="t-' + (id || name) + '"><a href="#">' + name + '</a></li>').appendTo($tools).click(action);
		}
	};
	mw.hook('wikibooks.panels.tools').fire(mw, $);
})(mediaWiki, jQuery);