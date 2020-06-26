var datatables = {}; // save all instances for nicescroll

$(document).on("shiny:busy shiny:connected", function() {
	if (!$(".loader").length) {
		var html = "<div class='loader fa-3x'><i class='fas " +
				   "fa-circle-notch fa-spin'></i></div>";

		$(html).hide().appendTo("body").fadeIn();
	}
});

$(document).on("shiny:idle", function() {
	$("body").find(".loader").fadeOut().remove();

	$(".modal-body").niceScroll({
		autohidemode: true, cursorcolor: "#f1f3f4",
		horizrailenabled: false, enableobserver: false
	});

	$(".gallery-container").niceScroll({
		autohidemode: true, cursorcolor: "#f1f3f4",
		horizrailenabled: false, enableobserver: false
	});
});

$(document).on("DOMSubtreeModified", ".modal.show .progress-bar", function() {
	var module_id = $($(this).closest(".modal-body")[0]).attr("data-id");

	var title = this.innerText; var parent = $(this).parent()[0];
	var form_group = $(this).closest(".form-group")[0];

	var file_input = $(form_group).find("input")[0];
	var file_text = $(form_group).find("input")[1];

	var valid_ext = $(file_input).attr("accept").split(",");
	var file_ext = $(file_text).val().split(".").pop();

	if (valid_ext.includes("." + file_ext) === false) {
		title = "Non-compatible file format";
	}

	$(parent).prop("title", title); // change title of parent
	Shiny.setInputValue(module_id + "-file_progress_bar", title);
});

Shiny.addCustomMessageHandler("disable", function(element) {
	$(element).addClass("disabled");
});

Shiny.addCustomMessageHandler("enable", function(element) {
	$(element).removeClass("disabled");
});

Shiny.addCustomMessageHandler("show", function(element) {
	$(element).css("display", "flex");
	$(element).css("height", "100%");
});

Shiny.addCustomMessageHandler("hide", function(element) {
	$(element).css("display", "none");
	$(element).css("height", "0");
});

Shiny.addCustomMessageHandler("click", function(element) {
	$(element).click();
});

$(document).on("click", "a.disabled", function(event) {
	event.preventDefault();
});

$(document).on("show.bs.modal", ".modal", function() {
    var input_id = $($(this).find(".modal-body")[0]).attr("data-id");
	Shiny.setInputValue(input_id + "-modal", true, {priority: "event"});
});
