# module user interface
preprocess_ui <- function(id) {
  ns <- NS(id)

  htmltools::htmlTemplate(
    filename = "www/modules/section/index.html",

    content_id = gsub("-$", "", ns("")),
    data_output = dataTableOutput(ns("data")),
    history = history_ui(ns("history"))
  )
}

# module server logic
preprocess <- function(input, output, session) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))
  fcts <- read_fcts(glue("data/{id}-history.yaml"))

  history <- callModule(history, id = "history", fcts, run_fct)
  values <- reactiveValues(tasks = tibble(), data = NULL)

  run_fct <- function(data, tasks) {
    data <- as.data.frame(data)

    for (i in seq_len(nrow(tasks))) {
      task <- tasks[i, ]; arg_data <- list(data)

      if (task$item_checked) {
        message <- customTryCatch({
          fct <- filter(fcts, name == task$fct)
          names(arg_data)[1] <- names(fct$args)[1]

          args <- filter(task$args[[1]], value != "")
          args <- glue_data(args, "{name} = {value}")
          args <- call_args(args, arg_data)

          data <- do.call(task$fct, args = args)
        })

        if (!is.null(message$error)) {
          tasks$item_status[i] <- "error"
          message <- capture.output(message$error)
        } else if (!is.null(message$warning)) {
          tasks$item_status[i] <- "warning"
          message <- capture.output(message$warning)
        } else {
          tasks$item_status[i] <- "success"
          message <- NA # no further messages
        }

        if (!is.na(message[1])) {
          message <- paste(message, collapse = "\n")
        }

        tasks$message[i] <- message[1]
      } else {
        tasks$item_status[i] <- ""
        message <- NA # no further messages
      }
    }

    return(list(data = as_tibble(data), tasks = tasks))
  }

  observeEvent(values$data, {
    data <- head(values$data, n = 1) # selected data set
    tasks <- tibble(data_id = data$data_id, tasks = list(NULL))

    if (data$data_id %in% values$tasks$data_id) {
      tasks <- filter(values$tasks, data_id == data$data_id)
    }

    data <- left_join(data, tasks, by = "data_id")
    history$set_data(select(data, original, tasks))
  })

  observeEvent(history$get_data(), {
    values$data$active[[1]] <- history$get_data()
  })

  observeEvent(history$get_tasks(), {
    data_id <- head(values$data, n = 1)$data_id

    values$tasks <- tibble(data_id = data_id) %>%
      mutate(tasks = list(history$get_tasks())) %>%
      bind_rows(values$tasks, .id = NULL) %>%
      distinct(data_id, .keep_all = TRUE)
  })

  output$data <- renderDataTable({
    no_data_id <- glue("#{id} > div > .no-selection")
    data_id <- glue("#{id} > div > .selection")

    session$sendCustomMessage("show", no_data_id)
    session$sendCustomMessage("hide", data_id)

    req(try(is_tibble(values$data$active[[1]])))

    session$sendCustomMessage("hide", no_data_id)
    session$sendCustomMessage("show", data_id)

    head(values$data, n = 1)$active[[1]]
  },
  escape = FALSE, rownames = FALSE, style = "bootstrap",
  filter = "top", server = TRUE, options = list(
    lengthChange = FALSE, searchHighlight = TRUE,
    pageLength = 100, info = TRUE, pagingType = "numbers",
    search = list(smart = FALSE), rowCallback = JS(
      'function(row, data, index, indexfull) {
        for (var i = 0; i < data.length; i++) {
          $("td:eq(" + i + ")", row).attr("title", data[i]);
        }
      }'
    ),
    initComplete = JS(
      'function(settings, json) {
        Object.keys(datatables).forEach(function(key) {
          datatables[key].hide().remove();
        });

        datatables = {}; // reset instances

        new_scroll = $(this).niceScroll({
  		    autohidemode: true, cursorcolor: "#f1f3f4",
  		    horizrailenabled: true, enableobserver: false
  		  });

  		  datatables[$(this)[0].id] = new_scroll;
      }'
    )
  )
  )

  outputOptions(output, "data", suspendWhenHidden = FALSE)

  list(
    set_visible = function(close) {
      session$sendCustomMessage(
        "set-visible", list(id = id, close = close)
      )
    },
    set_data = function(data) {
      data <- mutate(data, active = original)

      if (data$data_id %in% values$data$data_id) {
        data <- filter(values$data, data_id == data$data_id)
      }

      values$data <- bind_rows(data, values$data) %>%
        distinct(data_id, .keep_all = TRUE)
    },
    get_data = function() {
      req("active" %in% colnames(values$data))

      select_data <- head(values$data, n = 1) %>%
        select_if(!(names(.) %in% c("history", "original")))

      return(mutate(select_data, original = active))
    },
    get_export = function() {
      if (nrow(values$tasks) == 0) return(values$data)

      return(inner_join(values$data, values$tasks))
    }
  )
}
