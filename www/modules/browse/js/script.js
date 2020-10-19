$(document).on("shiny:sessioninitialized", function(event) {
	Split(['#split-gallery', '#split-tree'], {
		sizes: [75, 25], cursor: 'col-resize', gutterSize: 2,
		elementStyle: function (dimension, size, gutterSize) {
			return {
				'flex-basis': 'calc(' + size + '% - ' + gutterSize + 'px)',
			}
		},
		gutterStyle: function (dimension, gutterSize) {
			return {
				'flex-basis': gutterSize + 'px',
			}
		},
	});

	$(document).on("mouseover", ".modal-image .right img", function() {
		var left = $(this).offset().left + $(this).width();

		$("body").append(
			"<div class='tooltip' style='left: " + left + "px; " +
			"top: " + $(this).offset().top + "px;'></div>"
		);

		$(this).clone().appendTo(".tooltip");
		$(".tooltip").hide().fadeIn("slow");  
	});

	$(document).on("mouseout", ".modal-image .right img", function() {
		$(".tooltip").remove();
	});

	$(document).on("click", ".modal-image .right img", function() {
		var resource_id = $(this).attr("data-resource-id")
		var section_id = "browse-gallery-show_click_";

		Shiny.setInputValue(section_id + "resource_id", resource_id, {priority: "event"});
		Shiny.setInputValue(section_id + "value", "details", {priority: "event"});

		Shiny.setInputValue(section_id + "image", [
			$(this)[0].naturalWidth, $(this)[0].naturalHeight, $(this)[0].src
		], {priority: "event"});
	});

	$(document).on("click", ".modal-image .right code", function() {
		var section_id = "browse-tree-show_";

		Shiny.setInputValue(section_id + "search", $(this).text(), {priority: "event"});
		Shiny.setInputValue(section_id + "code", true, {priority: "event"});
	});
});

Shiny.addCustomMessageHandler("browse-tree-set", function(args) {
	var tree_id = "#browse-tree-show .tree-container";

	$(tree_id).jstree(true).uncheck_all();
	$(tree_id).jstree(true).select_node(args);
});

Shiny.addCustomMessageHandler("browse-gallery-reset", function(args) {
	$("#browse-gallery-show input[type='search']").val("");
});
