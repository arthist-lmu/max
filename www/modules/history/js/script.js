var interval_id;

$(document).on("shiny:sessioninitialized", function() {
	$(".history-items > div").niceScroll({
		autohidemode: true, cursorcolor: "#f1f3f4",
		horizrailenabled: false, enableobserver: false
	});

	$(".history > .add-task .left > i").on("click", function() {
		var input_id = get_history_id(this) + "-add_task";
		Shiny.setInputValue(input_id, true, {priority: "event"});
	});

	$(".history > .run-tasks").on("click", function() {
		var input_id = get_history_id(this) + "-run_tasks";
		Shiny.setInputValue(input_id, true, {priority: "event"});
	});

	$(document).on("click", ".history .dropdown-item", function() {
		var input_id = get_history_id(this) + "-task_options";
		var input_text = this.innerText.trim();

		input_text = {"item_id": get_item_id(this), "text": input_text};
		Shiny.setInputValue(input_id, input_text, {priority: "event"});
	});

	$(document).on("change", ".history input[type=checkbox]", function() {
		var input_id = get_history_id(this) + "-task_checked";
		var item = $($(this).closest(".history-item")[0]);
		var input_text = $(this).prop("checked");

		if (input_text) item.addClass("checked");
		else item.removeClass("checked");

		input_text = {"item_id": get_item_id(this), "text": input_text};
		Shiny.setInputValue(input_id, input_text, {priority: "event"});
	});

	$(document).on("change", ".history-functions select", function() {
		var input_id = get_history_id(this) + "-task_select";
		var input_text = this.value.trim(); 

		input_text = {"item_id": get_item_id(this), "text": input_text};
		Shiny.setInputValue(input_id, input_text, {priority: "event"});
	});

	$(document).on("mouseenter", ".history-item", function() {
		var input_id = get_history_id(this) + " .history-item";

		$("#" + input_id).removeClass("active");
		$(this).addClass("active"); 

		var input_id = get_history_id(this) + "-task_active";
		var input_text = {"item_id": get_item_id(this)};

		Shiny.setInputValue(input_id, input_text);
	});

	$(document).on("mouseenter", ".history-args .args-box > div", function() {
		var input_id = get_history_id(this) + " .history-args .args-box > div";
		$("#" + input_id).removeClass("open"); $(this).addClass("open"); 
	});

	$(document).on("click", ".history-args > i", function() {
		var args_box = $($(this).parent()[0]).find(".args-box");
		side_scroll(args_box[0], $(this).attr("title"), 100);
	});

	$(document).on("mouseleave", ".history-args input.form-control", function() {
		var input_id = get_history_id(this) + "-task_args";
		var item_id = $(this).closest(".history-item")[0];

		var args = {}; 

		$(item_id).find("input.form-control").each(function(index, value) {
			var arg_name = $($(value).parent()[0]).find("code");
			args[arg_name[0].innerText] = $(value).val();
		});

		input_text = {"item_id": get_item_id(this), "text": args};
		Shiny.setInputValue(input_id, input_text);
	});

    $(".history-items > div, .history-items li").disableSelection();

    $(".history-items > div").sortable({
    	placeholder: "slide-placeholder", axis: "y", revert: 150,

    	start: function(event, ui) {
    		placeholder_height = ui.item.outerHeight();
    		ui.placeholder.height(placeholder_height);

    		$('<div class="slide-placeholder-animator" data-height="' + 
    			placeholder_height + '"></div>').insertAfter(ui.placeholder);
	    },

		change: function(event, ui) {
			ui.placeholder.stop().height(0).animate({height: ui.item.outerHeight()}, 300);
			animator_height = parseInt($(".slide-placeholder-animator").attr("data-height"));
	        
			$(".slide-placeholder-animator").stop().height(animator_height).animate({
	            height: 0
	        }, 300, function() {
	            $(this).remove(); placeholder_height = ui.item.outerHeight();

	            $('<div class="slide-placeholder-animator" data-height="' + 
	            	placeholder_height + '"></div>').insertAfter(ui.placeholder);
	        }); 
	    },

		stop: function(event, ui) {
			$(".slide-placeholder-animator").remove();

			var input_id = get_history_id(this) + "-task_order";
			var items = $(this).find(".history-item");

			var item_ids = jQuery.map(items, function(element, index) {
				return $(element).attr("data-id");
			});

			Shiny.setInputValue(input_id, item_ids);
	    },
	});
});

function side_scroll(element, direction, value = 1, speed = "fast") {
	if (direction == "Move left") {
		$(element).animate({scrollLeft: "-=" + value.toString()}, speed);
	} else if (direction == "Move right") {
		$(element).animate({scrollLeft: "+=" + value.toString()}, speed);
	}
}

function get_history_id(element) {
	return $(element).closest(".history")[0].id;
}

function get_item_id(element) {
	var item_id = $(element).closest(".history-item");

	if (item_id.length) {
		return $(item_id[0]).attr("data-id").trim();
	}

	return null;
}
