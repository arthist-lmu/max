htmltools::htmlTemplate(
  filename = "www/index.html",
  header = header_ui("header"),

  browse = browse_ui("browse"),
  preprocess = preprocess_ui("preprocess"),
  visualize = visualize_ui("visualize"),

  stylesheets = get_stylesheets(),
  scripts = get_scripts()
)
