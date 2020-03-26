# module user interface
header_export_ui <- function(id) {
  ns <- NS(id)

  show_modal(
    checkboxInput(ns("code"), "Generate reproducible code", FALSE),
    downloadButton(ns("button"), "Export data", class = "disabled"),
    title = "Information", `data-id` = gsub("-$", "", ns("")),
    size = "s" # note: reference by `data-id` in javascript
  )
}

# module server logic
header_export <- function(input, output, session) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))

  values <- reactiveValues(data = NULL)

  observeEvent(input$modal, {
    export <- glue(".modal-body[data-id=\"{id}\"] .btn")
    session$sendCustomMessage("disable", export)

    req(values$data, nrow(values$data) > 0)
    session$sendCustomMessage("enable", export)
  })

  output$button <- downloadHandler(
    filename = function() {
      glue("data-{Sys.Date()}.zip")
    },
    content = function(connect) {
      message <- customTryCatch({
        temp_dir <- tempdir(check = TRUE)
        unlink(glue("{temp_dir}\\*"), TRUE)

        save_data <- function(x, y, name = "data") {
          if (nrow(x) > 0) {
            saveRDS(x, file = glue("{y}\\{name}.rds"))
          }
        }

        data <- filter(values$data, tab == "header") %>%
          mutate(folder = gsub(" ", "-", tolower(label))) %>%
          mutate(folder = glue("{temp_dir}\\{folder}"))

        map(data$folder, dir.create, showWarnings = FALSE)

        values$data %>% group_by(data_id) %>% nest() %>%
          mutate(data = map(data, ~ bind_rows(.x$tasks))) %>%
          rename(tasks = data) %>% right_join(data, NULL) %>%
          mutate(pmap(list(original, folder), save_data)) %>%
          mutate(pmap(list(tasks, folder, "tasks"), save_data))

        print(list.files(temp_dir, recursive = TRUE))

        if (input$code) {

        }

        zip::zipr(zipfile = connect, files = data$folder)
      })

      print(message)
    }
  )

  list(
    set_data = function(data) {
      values$data <- data
    }
  )
}
