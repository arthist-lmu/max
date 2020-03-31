# module user interface
header_import_ui <- function(id) {
  ns <- NS(id)

  show_modal(
    textInput(
      ns("name"), label = "", placeholder = "Name of data set"
    ),
    fileInput(
      ns("file"), label = "", placeholder = "Select data file",
      accept = c(".txt", ".csv", ".rds", ".json", ".xls", ".xlsx"),
      buttonLabel = icon("file-spreadsheet")
    ),
    actionButton(ns("button"), "Import data", class = "disabled"),
    title = "Information", `data-id` = gsub("-$", "", ns("")),
    size = "s" # note: reference by `data-id` in javascript
  )
}

# module server logic
header_import <- function(input, output, session) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))

  values <- reactiveValues(data = NULL)

  observeEvent(input$file, {
    values$data <- repair(as_tibble(input$file, .rows = NULL))
    ext <- get_ext(input$file$name, convert = FALSE)

    if (input$name == "") {
      value <- gsub(glue("\\.{ext}"), "", input$file$name)
      updateTextInput(session, "name", value = value)
    }
  })

  observeEvent(input$file_progress_bar, {
    import <- glue(".modal-body[data-id=\"{id}\"] .btn")
    session$sendCustomMessage("disable", import)

    req(input$file_progress_bar == "Upload complete")
    session$sendCustomMessage("enable", import)
  })

  list(
    get_data = function() {
      req(input$button, isolate(values$data))

      isolate({
        message <- customTryCatch({
          ext <- get_ext(values$data$name, convert = TRUE)
          args <- list(file = values$data, `...` = NULL)

          data <- do.call(glue("import_{ext}"), args = args)
          data <- as_tibble(data, .name_repair = "minimal")
        })

        removeModal() # show errors afterwards in a new modal

        if (is.null(message$error)) {
          tibble(
            path = values$data$datapath, rows = nrow(data),
            cols = ncol(data), label = input$name, lang = "",
            data_id = get_random_id(), original = list(data)
          )
        } else {
          message <- capture.output(message$error)
          message <- paste(message, collapse = "\n")[1]

          show_modal(tags$code(message), title = "Errors")
        }
      })
    }
  )
}
