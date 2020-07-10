var first_load = true;

$(document).on("shiny:idle", function() {
	if (first_load && $("#browse .gallery .jp_bottom").length) {
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
					element: "#browse .gallery",
					intro: "Predefined data sets can be displayed in form of a gallery."
				},
				{
					element: "#browse .gallery .jp_filter",
					intro: "To better explore them, they can be filtered either via their metadata ..."
				},
				{
					element: "#browse .tree > .box",
					intro: "... or via annotations defined using the <i>Iconclass</i> classification system."
				},
				{
					element: "#browse .gallery .jp_icons",
					intro: "The dates of origin of the filtered objects can be easily compared in relation to all objects.",
					onExit: function() {
						$("a.header-nav-item[title='Preprocess']").click();
					}
				},
				{
					element: "#header .header-search",
					intro: "Now, either load one of the predefined data sets or import your own."
				},
				{
					element: "#preprocess .no-selection",
					intro: "Your currently selected data set is displayed here, either as a table or a plot."
				},
				{
					element: "#header .header-nav",
					intro: "You can then preprocess and visualize this data, e.g., standardize dates or draw a boxplot."
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
					intro: "Each task can be further specified, e.g., you can temporarily deactivate it. The order of the tasks can be changed with <i>drag & drop</i>."
				},
				{
					element: "#preprocess-history .run-tasks",
					intro: "Finished? Let’s run the selected tasks to see if they can be completed successfully. If not, the respective task is marked yellow (a <i>warning</i> has occurred) or red (an <i>error</i> has occurred)."
				},
				{
					element: "#header .header-link-item[title=\"Export\"]",
					intro: "The processed, cleansed, and visualized data can be exported as a <code>.zip</code> file."
				}
			]
		});

		intro.onchange(function() {
			var index = this._currentStep + ((this._direction == 'backward')? 1 : -1);

			if (
				typeof this._introItems[index] !== 'undefined' && 
				typeof this._introItems[index].onExit === 'function'
			)
				this._introItems[index].onExit();

			if (
				typeof this._introItems[this._currentStep] !== 'undefined' && 
				typeof this._introItems[this._currentStep].onEnter === 'function'
			)
				this._introItems[this._currentStep].onEnter();
		})

		intro.start();
		first_load = false; 
	}
});
