# module user interface
history_ui <- function(id) {
  ns <- NS(id)

  htmltools::htmlTemplate(
    filename = "www/modules/history/index.html",

    history_id = gsub("-$", "", ns("")),
    history_items = uiOutput(ns("items")),

    download = downloadButton(
      ns("download"), label = "Export tasks",
      title = "Export tasks", class = "dropdown-item"
    )
  )
}

# module server logic
history <- function(input, output, session, fcts, run_fct) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))

  import <- callModule(history_import, id = "import")
  values <- reactiveValues(tasks = NULL, data = NULL)

  observeEvent(import$get_data(), {
    data <- import$get_data()$data %>%
      filter(fct %in% fcts$name) # basic check

    if (import$get_data()$append) {
      values$tasks <- bind_rows(values$tasks, data)
    } else {
      values$tasks <- data # remove previous tasks
    }
  })

  observeEvent(input$add_task, {
    req(values$data, nrow(values$data) > 0)

    new_task <- tibble(
      item_id = get_random_id(), fct = "", args = list(""),
      item_checked = FALSE, item_status = "", item_active = ""
    )

    values$tasks <- bind_rows(values$tasks, new_task)
  })

  observeEvent(input$task_options, {
    req(values$data, nrow(values$data) > 0)
    item_id <- input$task_options$item_id

    if (input$task_options$text == "Delete task") {
      values$tasks <- filter(values$tasks, item_id != !!item_id)
    }

    if (input$task_options$text == "Show help") {
      html <- filter(values$tasks, item_id == !!item_id)$fct %>%
        load_help(pkg = filter(fcts, name == .)$package)

      show_modal(html$content, title = html$title)
    }

    if (input$task_options$text == "Show warnings") {
      task <- filter(values$tasks, item_id == !!item_id)
      show_modal(tags$code(task$message), title = "Warnings")
    }

    if (input$task_options$text == "Show errors") {
      task <- filter(values$tasks, item_id == !!item_id)
      show_modal(tags$code(task$message), title = "Errors")
    }

    if (input$task_options$text == "Import tasks") {
      history_import_ui(ns("import")) # switch to import module
    }
  })

  output$download <- downloadHandler(
    filename = function() {
      glue("tasks-{Sys.Date()}.rds")
    },
    content = function(connect) {
      saveRDS(values$tasks, connect)
    }
  )

  observeEvent(input$task_checked, {
    values$tasks <- mutate(
      values$tasks, item_checked = replace(
        item_checked, item_id == input$task_checked$item_id,
        values = as.logical(input$task_checked$text)
      )
    )
  })

  observeEvent(input$task_order, {
    values_order <- tibble(item_id = input$task_order)
    values$tasks <- right_join(values$tasks, values_order)
  })

  observeEvent(input$task_select, {
    fct <- filter(fcts, name == input$task_select$text)
    item_checked <- if_else(nrow(fct) > 0, TRUE, FALSE)

    if (nrow(fct) == 0) fct <- list(args = "")
    else fct$args <- list(fct$args[[1]][-1, ])

    item_id <- input$task_select$item_id

    values$tasks <- values$tasks %>%
      mutate(
        args = replace(
          args, item_id == !!item_id, !!fct$args
        ),
        fct = replace(
          fct, item_id == !!item_id, input$task_select$text
        ),
        item_checked = replace(
          item_checked, item_id == !!item_id, !!item_checked
        )
      )
  })

  observeEvent(input$task_active, {
    values$tasks <- mutate(
      values$tasks, item_active = if_else(
        item_id == input$task_active$item_id, "active", ""
      )
    )
  })

  observeEvent(input$task_args, {
    item_id <- input$task_args$item_id
    args <- input$task_args$text

    task <- filter(values$tasks, item_id == !!item_id)
    task$args[[1]]$value <- unlist(enframe(args)$value)

    values$tasks <- values$tasks %>%
      mutate(
        args = replace(
          args, item_id == !!item_id, task$args
        )
      )
  })

  observeEvent(input$run_tasks, {
    req(values$tasks, nrow(values$tasks) > 0)
    req(values$data, nrow(values$data) > 0)

    result <- run_fct(values$data, values$tasks)

    values$data <- result$data
    values$tasks <- result$tasks
  })

  observe({
    run_tasks <- glue("#{id} .run-tasks")
    download <- glue("#{id}-download")

    session$sendCustomMessage("disable", run_tasks)
    session$sendCustomMessage("disable", download)

    req(values$tasks, sum(values$tasks$item_checked) > 0)

    session$sendCustomMessage("enable", run_tasks)
    session$sendCustomMessage("enable", download)
  })

  observe({
    import <- glue("#{id} div[title=\"Import tasks\"]")
    session$sendCustomMessage("disable", import)

    req(values$data, nrow(values$data) > 0)
    session$sendCustomMessage("enable", import)
  })

  output$items <- renderUI({
    no_data_id <- glue("#{id} > ul > .no-selection")
    session$sendCustomMessage("show", no_data_id)

    req(values$tasks, nrow(values$tasks) > 0)
    req(values$data, nrow(values$data) > 0)

    session$sendCustomMessage("hide", no_data_id)

    reload_history(values$tasks, fcts)$html
  })

  outputOptions(output, "items", suspendWhenHidden = FALSE)

  list(
    set_data = function(data) {
      values$data <- data$original[[1]]
      values$tasks <- data$tasks[[1]]
    },
    get_data = function() {
      req(input$run_tasks)
      return(isolate(values$data))
    },
    get_tasks = function() {
      return(values$tasks)
    }
  )
}

convert_args <- function(args) {
  if (!is_tibble(args)) return(list("")) # no known arguments

  args <- mutate(args, value = gsub('"', "'", value, fixed = TRUE))
  html <- args %>% map_template(., "www/modules/history/args.html")

  return(list(HTML(paste(html, sep = "", collapse = "\n"))))
}

reload_history <- function(history, fcts) {
  apply_selectize <- function(item_id, fct) {
    select_task <- selectizeInput(
      paste0("input-", item_id), label = "", choices = choices,
      options = selectize_options(placeholder = "Select task"),
      selected = fct, multiple = FALSE, width = "100%"
    )

    return(HTML(paste0(select_task)))
  }

  choices <- c("", setNames(fcts$name, fcts$label))

  history %>%
    mutate(
      item_checked = if_else(item_checked, "checked", ""),
      item_disabled = if_else(fct == "", "disabled", ""),
      fcts = pmap(list(item_id, fct), apply_selectize),
      args = map(args, convert_args)
    ) %>%
    mutate(
      html = map_template(., "www/modules/history/item.html")
    )
}
