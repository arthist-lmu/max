# module user interface
browse_viewer_ui <- function(id) {
  ns <- NS(id)

  leafletOutput(ns("img_plot"), height = 500)
}

# module server logic
browse_viewer <- function(input, output, session) {
  values <- reactiveValues(image = NULL, points = NULL)

  observeEvent(input$img_plot_points, {
    values$points <- input$img_plot_points
  })

  output$img_plot <- renderLeaflet({
    leaflet() %>% onRender(
      get_overlay(values$image, isolate(values$points))
    )
  })

  list(
    set_data = function(data) {
      values$image <- data$image
      values$points <- data$points
    },
    get_points = function() {
      return(values$points)
    }
  )
}

get_overlay <- function(image, points = NULL) {
  if (is.null(points) | length(points) == 0) points <- ""

  if (is.list(points)) {
    points <- unname(unlist(points, recursive = TRUE))
    points <- split(points, ceiling(seq_along(points) / 2))

    points <- lapply(points, function(x) {
      glue("[{paste0(x, collapse = ', ')}]")
    })

    points <- paste0(unlist(points), collapse = ", ")
  }

  render_text <- glue(
    "function(el, x) {{
      var map = this; // Instance of leaflet map

      L.tileLayer.iiif('{image}').addTo(map);
      map.addControl(new L.Control.Fullscreen());
    }}"
  )

  return(render_text)
}
