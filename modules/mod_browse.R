# module user interface
browse_ui <- function(id) {
  ns <- NS(id)

  htmltools::htmlTemplate(
    filename = "www/modules/browse/index.html",

    content_id = gsub("-$", "", ns("")),
    gallery = browse_gallery_ui(ns("gallery")),
    tree = browse_tree_ui(ns("tree"))
  )
}

# module server logic
browse <- function(input, output, session) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))

  tree <- callModule(browse_tree, id = "tree")
  gallery <- callModule(browse_gallery, id = "gallery")

  values <- reactiveValues(data = NULL, user = NULL)

  observeEvent(values$data, {
    tree$set_url(values$data$url)
  })

  observeEvent(values$user, {
    gallery$set_user(values$user)
  })

  observeEvent(tree$get_data(), {
    gallery$set_data(tree$get_data())
  })

  list(
    set_visible = function(close) {
      session$sendCustomMessage(
        "set-visible", list(id = id, close = close)
      )
    },
    set_data = function(data) {
      values$data <- data
    },
    set_user = function(user) {
      values$user <- user
    }
  )
}
