Shiny.addCustomMessageHandler("set-visible", function(args) {
	args.class = $("#" + args.id)[0].classList[0];

	if (args.close) {
		$("." + args.class).css("display", "none");	
	}
	
	$("#" + args.id).css("display", "flex");

	Object.keys(datatables).forEach(function(key) {
        datatables[key].resize();
    });

    $(".history-items > div").getNiceScroll().resize();
});
