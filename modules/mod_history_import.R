# module user interface
history_import_ui <- function(id) {
  ns <- NS(id)

  show_modal(
    fileInput(
      ns("file"), label = "", placeholder = "Select data file",
      accept = c(".rds"), buttonLabel = icon("file-spreadsheet")
    ),
    checkboxInput(ns("append"), "Append to existing tasks", FALSE),
    actionButton(ns("button"), "Import tasks", class = "disabled"),
    title = "Information", `data-id` = gsub("-$", "", ns("")),
    size = "s" # note: reference by `data-id` in javascript
  )
}

# module server logic
history_import <- function(input, output, session) {
  ns <- session$ns

  values <- reactiveValues(data = NULL)

  observeEvent(input$file, {
    values$data <- as_tibble(input$file, .rows = NULL)
  })

  observeEvent(input$file_progress_bar, {
    import <- "#shiny-modal .modal-body .btn"
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
          data <- as_tibble(data, .name_repair = "universal")

          columns <- c("item_id", "fct", "args", "item_checked")

          if (!all(columns %in% colnames(data))) {
            stop("Input can not be converted to list of tasks.")
          }
        })

        removeModal() # show errors afterwards in a new modal

        if (is.null(message$error)) {
          data <- mutate(data, item_status = "", active = "")

          return(list(data = data, append = input$append))
        } else {
          message <- capture.output(message$error)
          message <- paste(message, collapse = "\n")[1]

          show_modal(tags$code(message), title = "Errors")
        }
      })
    }
  )
}
