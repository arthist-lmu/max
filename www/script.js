window.onload = function() {
	document.getElementsByTagName('html')[0].setAttribute('lang', 'de'); 
	$('#loading-content .progress-bar').css('width', '100%');
	$('.wrapper').data('museum', {count: 0});
	$('.wrapper').data('history', {count: 0});
};

$(function() {
	var dashboard_progress_observer = new MutationObserver(
	    function (mutations) {
	        Shiny.onInputChange('dashboard_import_progress_bar', $('.tab-content .row .progress-bar').text());
	    }
	);

	var preprocessing_progress_observer = new MutationObserver(
	    function (mutations) {
	    	if ($('#preprocessing_load_history_button_progress').length > 0) {
		        Shiny.onInputChange('preprocessing_history_progress_bar', $('#preprocessing_load_history_button_progress .progress-bar').text());
		    }

		    option = $('#preprocessing_select_operation').find("option");

		    if (option.length > 0) {
	    		value = option.attr("value");

	    		if(value == "") {
	    			$('#preprocessing_video').css("display", "none");
	    		} else {
	    			$('#preprocessing_video').css("display", "block");
	    		}
	    	}
	    }
	);

	var preprocessing_table_observer = new MutationObserver(function(mutations) {
		mutations.forEach(function(mutation) {
			if ($('#preprocessing_preview').length > 0) {
				field = '#preprocessing_preview .dataTables_filter input'
				$(field).attr("title", "Dieser Filter ermöglicht es Ihnen, in allen Spalteninhalten zu suchen");

				$("#preprocessing_preview").find(".table.dataTable thead th").each(function(ev) {
					if (!$(this).val()) {
						$(this).attr("data-original-title", $(this).attr("aria-label"));
						$(this).attr("data-toggle", "tooltip");
						$(this).attr("data-placement", "auto top");
					}
				});

				$("#preprocessing_preview").find(".table.dataTable thead .form-control").each(function(ev) {
					if (!$(this).val()) {
						$(this).attr("placeholder", "Filter");
					}
				});
			}
		});
	});

	var new_column_observer = new MutationObserver(
	    function (mutations) {
	    	if ($('#preprocessing_new_column_check').length > 0) {
	    		if (!$("#preprocessing_new_column_check").prop('checked')) {
	    			var object = $("#preprocessing_new_column_text").parent();
	    			object.css("display", "none");
	    		}
	    	}
	    }
	);

	var dashboard_table_load_observer = new MutationObserver(function(mutations) {
		mutations.forEach(function(mutation) {
			if ($('#dashboard_load').length > 0) {
				field = '#dashboard_load .dataTables_filter input'
				$(field).attr("title", "Wenn Sie bspw. nur Museen anzeigen möchten, deren Name mit „B“ beginnt, geben Sie „^B“ ein");

				$("#dashboard_load").find(".table.dataTable thead th").each(function(ev) {
					if(!$(this).val() & !$(this).hasClass("sorting_disabled")) {
						$(this).attr("data-original-title", $(this).attr("aria-label"));
						$(this).attr("data-toggle", "tooltip");
						$(this).attr("data-placement", "auto top");
					}
				});

				if(document.querySelector('#dashboard_load').innerHTML.indexOf("National Library of Denmark") >= 0){
	                Shiny.onInputChange('dashboard_load_reload', 1);
	            } else {
	                Shiny.onInputChange('dashboard_load_reload', 0);
	            }
			}
		});
	});

	var dashboard_table_import_observer = new MutationObserver(function(mutations) {
		mutations.forEach(function(mutation) {
			if ($('#dashboard_import').length > 0) {
				field = '#dashboard_import .dataTables_filter input'
				$(field).attr("title", "Wenn Sie bspw. nur Museen anzeigen möchten, deren Name mit „B“ beginnt, geben Sie „^B“ ein");

				$("#dashboard_import").find(".table.dataTable thead th").each(function(ev) {
					if(!$(this).val() & !$(this).hasClass("sorting_disabled")) {
						$(this).attr("data-original-title", $(this).attr("aria-label"));
						$(this).attr("data-toggle", "tooltip");
						$(this).attr("data-placement", "auto top");
					}
				});
			}
		});
	});

	var visualize_error_observer = new MutationObserver(
	    function (mutations) {
	    	field = '#shiny-tab-visualize .col-sm-8 .shiny-output-error';
			$("#visualisierung_preview").attr('style', 'height: 600px; visibility: visible');

			if ($(field).length > 0) {
	    		if ($(field).text().length > 5) {
	    			$("#visualisierung_preview").attr('style', 'height: 20px; visibility: hidden');
	    		}
	    	}
	    }
	);

	var preprocessing_error_observer = new MutationObserver(
		function(mutations) {
			field = '#shiny-tab-preprocessing .col-sm-8 .shiny-output-error';
			$("#preprocessing_preview > div").attr('style', 'height: auto; overflow: auto');

			if ($(field).length > 0) {
	    		if ($(field).text().length > 5) {
	    			$("#preprocessing_preview > div").attr('style', 'height: 50px; overflow: hidden');
	    		}
	    	}
		}
	);

	var config = {attributes: true, childList: true, characterData: true};
	dashboard_progress_observer.observe(document.querySelector('.tab-content .row .progress-bar'), config);
	new_column_observer.observe(document.querySelector('#preprocessing_specify_operation'), config);
	visualize_error_observer.observe(document.querySelector('#shiny-tab-visualize'), config);
	preprocessing_error_observer.observe(document.querySelector('#shiny-tab-preprocessing'), config);

	var config = {childList: true, characterData: true, subtree: true};
	dashboard_table_load_observer.observe(document.querySelector('#dashboard_load'), config);
	dashboard_table_import_observer.observe(document.querySelector('#dashboard_import'), config);
	preprocessing_table_observer.observe(document.querySelector('#preprocessing_preview'), config);
    visualize_error_observer.observe(document.querySelector('#shiny-tab-visualize'), config);
	preprocessing_progress_observer.observe(document.body, config);
});

function change_dashboard_load_filter(value) {
	var field = '#dashboard_load .bottom .input-sm';
	document.querySelector(field).value = value;
	document.querySelector(field).focus();

	e = $.Event('keyup');
	e.keyCode = 13; // press enter
	$(field).trigger(e);
	$('[data-toggle="tooltip"]').tooltip("hide");
}

$(document).ready(function() {
    $('[data-toggle="tooltip"]').tooltip(); // $('[data-toggle="tooltip"]').tooltip("show");
});

(function( $ ) {
 	jQuery.fn.doubleScroll = function(userOptions) {
		var options = {
			contentElement: undefined, // Widest element, if not specified first child element will be used
			scrollCss: {                
				'overflow-x': 'auto',
				'overflow-y': 'hidden',
				'height': '17px'
			},
			contentCss: {
				'overflow-x': 'auto',
				'overflow-y': 'hidden'
			},
			onlyIfScroll: true, // top scrollbar is not shown if bottom one is not present
			resetOnWindowResize: true, // recompute top scrollbar requirements when window is resized
			timeToWaitForResize: 30 // wait for the last update event
		};
	
		$.extend(true, options, userOptions);
	
		$.extend(options, {
			topScrollBarMarkup: '<div class="doubleScroll-scroll-wrapper"><div class="doubleScroll-scroll"></div></div>',
			topScrollBarWrapperSelector: '.doubleScroll-scroll-wrapper',
			topScrollBarInnerSelector: '.doubleScroll-scroll'
		});

		var _showScrollBar = function($self, options) {
			if (options.onlyIfScroll && $self.get(0).scrollWidth <= $self.width()) {
				$self.prev(options.topScrollBarWrapperSelector).remove();
				return;
			}
		
			var $topScrollBar = $self.prev(options.topScrollBarWrapperSelector);
			
			if ($topScrollBar.length == 0) {
				$topScrollBar = $(options.topScrollBarMarkup);
				$self.before($topScrollBar);

				$topScrollBar.css(options.scrollCss);
				$(options.topScrollBarInnerSelector).css("height", "17px");
				$self.css(options.contentCss);

				$topScrollBar.bind('scroll.doubleScroll', function() {
					$self.scrollLeft($topScrollBar.scrollLeft());
				});

				var selfScrollHandler = function() {
					$topScrollBar.scrollLeft($self.scrollLeft());
				};

				$self.bind('scroll.doubleScroll', selfScrollHandler);
			}

			var $contentElement;		
			
			if (options.contentElement !== undefined && $self.find(options.contentElement).length !== 0) {
				$contentElement = $self.find(options.contentElement);
			} else {
				$contentElement = $self.find('>:first-child');
			}
			
			$(options.topScrollBarInnerSelector, $topScrollBar).width($contentElement.outerWidth());
			$topScrollBar.width($self.width());
			$topScrollBar.scrollLeft($self.scrollLeft());
		}
	
		return this.each(function() {
			var $self = $(this);
			_showScrollBar($self, options);
			
			if (options.resetOnWindowResize) {
				var id;
				var handler = function(e) {
					_showScrollBar($self, options);
				};
			
				$(window).bind('resize.doubleScroll', function() {
					clearTimeout(id);
					id = setTimeout(handler, options.timeToWaitForResize);
				});
			}
		});
	}
}(jQuery));