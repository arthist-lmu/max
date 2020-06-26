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
});

Shiny.addCustomMessageHandler("browse-gallery-reset", function(args) {
	$("#browse-gallery-show input[type='search']").val("");
});
