Shiny.addCustomMessageHandler("set-visible", function(args) {
	args.class = $("#" + args.id)[0].classList[0];

	if (args.close) {
		$("." + args.class).css("display", "none");	
	}

	$("#" + args.id).css("display", "flex");

    var sections = $("section.content:visible");
    var height = $("body > .wrapper").outerHeight() - 
    			 $("header.header").outerHeight();

    height = (height - (20 + 20 * (sections.length - 1))) / 
    		 sections.length - 40;

    $.each(sections, function(key, section) {
  		Shiny.onInputChange(
            section.id + "-height", height, {priority: "event"}
        );
  	});
});
