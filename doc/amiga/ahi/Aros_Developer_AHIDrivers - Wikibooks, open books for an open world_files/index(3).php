//<source lang="javascript">
// Faster Collapsible Containers
// Maintainer: [[User:Darklama]]

// images to use for hide/show states
var collapse_action_hide = '//upload.wikimedia.org/wikipedia/commons/1/10/MediaWiki_Vector_skin_action_arrow.png';
var collapse_action_show = '//upload.wikimedia.org/wikipedia/commons/4/41/MediaWiki_Vector_skin_right_arrow.png';
 
// toggle state of collapsible boxes
function collapsible_boxes()
{
	$('div.collapsible').each( function() {
		var $that = $(this), css_width = $that.css('width'), attr_width = $that.attr('width');
		var which = $that.hasClass('selected') ? collapse_action_show : collapse_action_hide;

		if ( (!css_width || css_width == 'auto') && (!attr_width || attr_width == 'auto') ) {
			$that.css('width', $that.width() );
		}

		$(this).children('.title').each( function() {
			$(this).prepend('<span class="action"><a><img src="'+which+'" /></a></span>').click( function() {
				var which = $that.toggleClass('selected').hasClass('selected')
					? collapse_action_show : collapse_action_hide;
				$(this).find('span.action img').attr('src', which);
				if ( which == collapse_action_show ) {
					$(this).siblings(':not(.title)').stop(true, true).fadeOut();
				} else {
					$(this).siblings(':not(.title)').stop(true, true).fadeIn();
				}
			}).click();
		});
	});

	$( "table.collapsible" ).each( function() {
		var $table = $(this), rows = this.rows, cell = rows.item(0).cells.item(0);
		var which = $table.hasClass('selected') ? collapse_action_show : collapse_action_hide;
		var css_width = $table.css('width'), attr_width = $table.attr('width');

		if ( (!css_width || css_width == 'auto') && (!attr_width || attr_width == 'auto') ) {
			$table.css('width', $table.width() );
		}

		$(cell).prepend('<span class="action"><a><img src="'+which+'" /></a></span>');
		$(rows.item(0)).click( function() {
			var which = $table.toggleClass('selected').hasClass('selected')
				? collapse_action_show : collapse_action_hide;
			$(cell).find('span.action img').attr('src', which);
			if ( which == collapse_action_show ) {
				$(rows).next().stop(true, true).fadeOut();
			} else {
				$(rows).next().stop(true, true).fadeIn();
			}
		}).click();
	});
}

$(document).ready( collapsible_boxes );

//</source>