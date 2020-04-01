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

        save_rds <- function(x, y, name = "data") {
          if (nrow(x) > 0) {
            saveRDS(x, file = glue("{y}\\{name}.rds"))
          }
        }

        save_pdf <- function(x, y, name = "plot") {
          if (length(x$layers) > 0) {
            ggsave(
              glue("{y}\\{name}.pdf"), plot = x,
              width = 15, height = 10, units = "cm"
            )
          }
        }

        convert_tasks <- function(tasks) {
          get_code <- function(fct, args) {
            args <- filter(args, value != "") %>%
              glue_data("{name} = {value}") %>%
              paste(sep = "", collapse = ", ")

            args <- gsub("... = ", "", args, fixed = TRUE)

            return(glue("{fct}({args})"))
          }

          tasks <- filter(tasks, nchar(fct) > 0) %>%
            mutate(
              code = pmap(list(fct, args), get_code),
              package = map_chr(fct, get_pkg)
            )

          return(tasks)
        }

        get_lines <- function(tab, tasks, pipe = "%>%") {
          if (tab == "visualize") pipe <- "+" else pipe <- "%>%"

          if (pipe == "+") {
            data <- glue("ggplot(data) {pipe}") # create mapping
          } else {
            data <- glue("data <- readRDS(\"data.rds\") {pipe}")
          }

          tasks <- convert_tasks(tasks) # get packages and code
          pkgs <- glue("library({unique(tasks$package)})")

          fcts <- rev(glue("\t{unlist(tasks$code)} {pipe}"))
          fcts[1] <- gsub(glue(" {pipe}"), "", fcts[1], fixed = TRUE)

          return(c(pkgs, "", data, rev(fcts), ""))
        }

        create_file <- function(lines, folder) {
          writeLines(unlist(lines), glue("{folder}\\code.R"))
        }

        data <- filter(values$data, nchar(tab) > 0) %>%
          mutate(folder = gsub(" ", "-", tolower(label))) %>%
          mutate(folder = glue("{temp_dir}\\{folder}"))

        map(data$folder, dir.create, showWarnings = FALSE)

        filter(data, tab == "header") %>%
          filter(map_lgl(original, ~ !is.null(.))) %>%
          mutate(pmap(list(original, folder), save_rds))

        filter(data, tab == "visualize") %>%
          filter(map_lgl(tasks, ~ !is.null(.))) %>%
          mutate(pmap(list(active, folder), save_pdf))

        filter(data, map_lgl(tasks, ~ !is.null(.))) %>%
          group_by(data_id, folder) %>% nest() %>%
          mutate(data = map(data, ~ bind_rows(.x$tasks))) %>%
          mutate(pmap(list(data, folder, "tasks"), save_rds))

        if (input$code) {
          filter(data, map_lgl(tasks, ~ !is.null(.))) %>%
            mutate(
              lines = pmap(list(tab, tasks), get_lines)
            ) %>%
            group_by(data_id, folder) %>% nest() %>%
            mutate(data = map(data, ~ c(.x$lines))) %>%
            mutate(pmap(list(data, folder), create_file))
        }

        # print(list.files(temp_dir, recursive = TRUE))
        zip::zipr(connect, files = unique(data$folder))
      })
    }
  )

  list(
    set_data = function(data) {
      values$data <- group_by(data, data_id)
    }
  )
}
