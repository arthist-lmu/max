$(document).on("shiny:sessioninitialized", function(event) {
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
});

Shiny.addCustomMessageHandler("browse-gallery-reset", function(args) {
	$("#browse-gallery-show input[type='search']").val("");
});
