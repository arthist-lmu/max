get_stylesheets <- function() {
  files <- list.files("www", pattern = "\\.css$", recursive = TRUE)
  files <- glue("<link rel=\"stylesheet\" href=\"{files}\">")

  return(HTML(glue_collapse(files, sep = "\n")))
}

get_scripts <- function() {
  files <- list.files("www", pattern = "\\.js$", recursive = TRUE)
  files <- glue("<script src=\"{files}\"></script>")

  return(HTML(glue_collapse(files, sep = "\n")))
}

map_template <- function(x, filename) {
  apply_template <- function(...) {
    return(HTML(paste0(do.call(htmlTemplate, list(...)))))
  }

  return(pmap(x, apply_template, filename = filename))
}

show_modal <- function(..., size = "l") {
  showModal(
    modalDialog(
      ..., size = size, easyClose = TRUE, fade = TRUE,
      footer = modalButton(icon("times"))
    )
  )
}

selectize_options <- function(...) {
  options <- list(
    dropdownParent = "body", # to prevent overflow issues
    render = I(
      '{
        item: function(item, escape) { return item.label; },
        option: function(item, escape) { return item.label; }
      }'
    ),
    onDropdownOpen = I(
      'function(dropdown) {
        var dropdown_content = $(this.$dropdown_content);

        if (dropdown_content.getNiceScroll().length) {
          dropdown_content.getNiceScroll().resize();
        } else {
          dropdown_content.niceScroll({
            autohidemode: true, cursorcolor: "#f1f3f4",
            horizrailenabled: false, enableobserver: false
          });
        }

        $(dropdown).on("mousedown", ".btn", function(event) {
          var value = $(this).parent().attr("data-value");
          var parent = $(this).closest("[id]")[0];

          Shiny.setInputValue(parent.id + "-button", {
            "data_id": value, "text": this.innerText
          }, {priority: "event"});

          event.stopImmediatePropagation();
        });
      }'
    )
  )

  return(c(list(...), options))
}

options(
  DT.options = list(
    lengthChange = FALSE, pagingType = "simple",
    info = FALSE, search = list(regex = TRUE),
    dom = "<\"top\">rt<\"bottom\"iflp><\"clear\">",
    language = list(
      search = "", searchPlaceholder = "Filter",
      info = "_START_ to _END_ of _TOTAL_ entries",
      paginate = list(
        `first` = "<i class='fa fa-angle-left'></i>",
        `previous` = "<i class='fa fa-angle-left'></i>",
        `next` = "<i class='fa fa-angle-right'></i>",
        `last` = "<i class='fa fa-angle-right'></i>"
      )
    )
  )
)
