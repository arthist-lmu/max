var first_load = true;

$(document).on("shiny:idle", function() {
	if (first_load) {
		var intro = introJs();

		intro.setOptions({
			nextLabel: "Next", prevLabel: "Back",
			hidePrev: true, hideNext: true,

			steps: [
				{
			 		intro: "In recent years, large museum databases have been created in the international museum sector that are awaiting meaningful use. They offer a hitherto unknown opportunity for empirical investigation of the history of collections, which can be expected to yield far-reaching results, especially in a comparative perspective. <i>Museum Analytics</i>, <i>MAX</i>, is intended to enable lecturers to import freely selectable museum databases and make them available to students for analysis.",
					tooltipClass: "wide"
				},
				{
					element: "#header .header-search",
					intro: "First, either load one of the predefined data sets or import your own."
				},
				{
					element: "#preprocess .no-selection",
					intro: "Your currently selected data set is displayed here, either as a table or a plot."
				},
				{
					element: "#header .header-nav",
					intro: "You can now preprocess and visualize this data, e.g., standardize dates or draw a boxplot."
				},
				{
					element: "#header .header-switch",
					intro: "If you do not want to separate preprocessing and visualization, you can also do both in one window."
				},
				{
					element: "#preprocess-history",
					intro: "This is where the magic happens. Here you can define tasks to be performed on your data set.",
					tooltipPosition: "left"
				},
				{
					element: "#preprocess-history .add-task .left > i",
					intro: "First, either add a new task ..."
				},
				{
					element: "#preprocess-history .add-task .right",
					intro: "... or import a file with tasks from a previous session."
				},
				{
					element: "#preprocess-history > ul",
					intro: "Each task can be further specified, e.g., you can temporarily deactivate or delete it. The order of the tasks can be changed with Drag & Drop."
				},
				{
					element: "#preprocess-history .run-tasks",
					intro: "Finished? Let’s run the selected tasks to see if they can be completed successfully. If not, the respective task is marked yellow (a <i>warning</i> has occurred) or red (an <i>error</i> has occurred)."
				}
			]
		});

		intro.start();
		first_load = false; 
	}
});
