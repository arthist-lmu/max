# module user interface
header_ui <- function(id) {
  ns <- NS(id)

  htmltools::htmlTemplate(
    filename = "www/modules/header/index.html",

    select_data = selectizeInput(
      ns("select"), label = "", choices = NULL
    ),

    username = textInput(ns("username"), icon("user")),
    password = passwordInput(ns("password"), icon("key")),
    response = htmlOutput(ns("response"), inline = TRUE)
  )
}

# module server logic
header <- function(input, output, session) {
  ns <- session$ns; id <- gsub("-$", "", ns(""))

  import <- callModule(header_import, id = "import")
  export <- callModule(header_export, id = "export")

  values <- reactiveValues(
    data = {
      readRDS("data/data-sets.rds") %>% rename(label = name) %>%
        mutate(data_id = strtrim(map_chr(path, digest), 10)) %>%
        mutate(text_button = "Load data", original = list(NULL))
    },
    user = NULL, selected = "" # use placeholder as default
  )

  observe({
    updateSelectizeInput(
      session, "select", choices = reload_header(values$data),
      options = selectize_options(placeholder = "Select data set"),
      selected = values$selected, server = FALSE
    )
  })

  observeEvent(import$get_data(), {
    values$data <- import$get_data() %>%
      mutate(text_button = "Delete data") %>%
      bind_rows(values$data, .id = NULL)

    values$selected <- values$data$data_id[1]
  })

  observeEvent(input$select, {
    if (input$select != "") {
      test <- filter(values$data, data_id == input$select)

      if (nrow(test) == 0) {
        header_import_ui(ns("import")) # switch to import module
      } else if (test$text_button == "Load data") {
        file_data <- repair(readRDS(glue("data/{test$path}")))

        values$data <- values$data %>%
          mutate(
            original = replace(
              original, data_id == test$data_id, list(file_data)
            ),
            text_button = replace(
              text_button, data_id == test$data_id, "Unload data"
            )
          )

        values$selected <- test$data_id # switch to loaded data
      }
    }
  })

  observeEvent(input$link, {
    if (input$link == "Export") {
      header_export_ui(ns("export")) # switch to export module
    }

    if (input$link == "About") {
      show_modal(
        htmltools::htmlTemplate(
          filename = "www/modules/header/about.html"
        ), title = "About the project"
      )
    }
  })

  observeEvent(input$button, {
    load_text <- c("Load data", "Unload data")
    import_text <- c("Import data", "Delete data")

    data_id <- input$button$data_id

    if (input$button$text %in% load_text) {
      values$data <- mutate(
        values$data, text_button = replace(
          text_button, data_id == !!data_id,
          setdiff(load_text, input$button$text)
        )
      )

      if (input$button$text == "Load data") {
        test <- filter(values$data, data_id == !!data_id)
        data <- repair(readRDS(glue("data/{test$path}")))

        values$data <- mutate(
          values$data, original = replace(
            original, data_id == !!data_id, list(data)
          )
        )

        values$selected <- data_id # switch to loaded data
      } else {
        values$selected <- "" # reset to placeholder
      }
    } else if (input$button$text %in% import_text) {
      if (input$button$text == "Import data") {
        header_import_ui(ns("import")) # switch to import module
      } else {
        values$data <- filter(values$data, data_id != !!data_id)
      }
    }
  })

  observeEvent(input$submit_login, {
    if (input$submit_login) {
      values$user <- tryCatch({
        for(connect in dbListConnections(RMySQL::MySQL()))
          dbDisconnect(connect) # close open connections

        connect <- dbConnect(
          RMySQL::MySQL(), user = input$username,
          dbname = glue("labuser_{input$username}"),
          password = input$password
        )

        list(connect = connect)
      }, error = function(error) {
        # TODO: open modal with error message

        return(NULL)
      })
    }
  })

  output$response <- renderUI({
    if (is.null(values$user)) {
      icon("times-circle")
    } else {
      icon("check-circle")
    }
  })

  outputOptions(output, "response", suspendWhenHidden = FALSE)

  list(
    get_tab = function() {
      if (!is.null(input$switch) && input$switch) return("")
      else return(input$nav) # only display specific tab
    },
    get_data = function() {
      data <- filter(values$data, data_id == input$select)
      if(nrow(data) == 0) data <- add_row(data, data_id = "0")

      return(data)
    },
    get_user = function() {
      return(values$user)
    },
    get_export = function() {
      return(filter(values$data, map_lgl(original, ~ !is.null(.))))
    },
    set_export = function(data) {
      export$set_data(data)
    }
  )
}

reload_header <- function(header) {
  header <- header %>%
    add_row(
      rows = 0, cols = 0, label = "Select own data set", lang = "",
      data_id = get_random_id(), text_button = "Import data"
    ) %>%
    mutate(
      data_class = if_else(
        grepl("load", tolower(text_button)), "load", "import"
      )
    ) %>%
    mutate(
      html = map_template(., "www/modules/header/item.html")
    ) %>%
    arrange(data_class, desc(text_button), label)

  return(c("", setNames(header$data_id, header$html)))
}
