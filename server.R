server <- function(input, output, session) {
  header <- callModule(header, id = "header")
  browse <- callModule(browse, id = "browse")

  preprocess <- callModule(preprocess, id = "preprocess")
  visualize <- callModule(visualize, id = "visualize")

  observeEvent(header$get_tab(), {
    if (header$get_tab() == "Browse") {
      browse$set_visible(close = TRUE)
    } else if (header$get_tab() == "Preprocess") {
      preprocess$set_visible(close = TRUE)
    } else if (header$get_tab() == "Visualize") {
      visualize$set_visible(close = TRUE)
    } else if (header$get_tab() == "") {
      browse$set_visible(close = FALSE)
      preprocess$set_visible(close = FALSE)
      visualize$set_visible(close = FALSE)
    }
  })

  observeEvent(header$get_data(), {
    browse$set_data(header$get_data())
    preprocess$set_data(header$get_data())
  })

  observeEvent(header$get_user(), {
    browse$set_user(header$get_user())
  })

  observeEvent(preprocess$get_data(), {
    visualize$set_data(preprocess$get_data())
  })

  observe({
    req(header$get_export(), nrow(header$get_export()) > 0)
    req(preprocess$get_export(), visualize$get_export())

    data <- bind_rows(
      mutate(header$get_export(), tab = "header"),
      mutate(preprocess$get_export(), tab = "preprocess"),
      mutate(visualize$get_export(), tab = "visualize")
    )

    header$set_export(filter(data, data_id != "0"))
  })
}
