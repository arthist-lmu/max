### General ###################################################################

dashboard_button_count <- '$(\".wrapper\").data(\"museum\").count'
save_museums <- reactiveValues(data = list(), id = NULL, names = NULL)
filter_museums <- reactiveValues(load = NULL, changed = FALSE)
import_museums <- reactiveValues(data = NULL, 
  file = NULL, header = TRUE, sep = ";")
progress_museums <- reactiveValues(object = NULL)

shinyjs::disable("dashboard_import_button")
shinyjs::disable("dashboard-import-file")
shinyjs::reset("dashboard-import-file")

### Videos ####################################################################

observeEvent(input$dashboard_load_video, {
  show_video(get("dashboard_load_video_url"))
})

observeEvent(input$dashboard_import_video, {
  show_video(get("dashboard_import_video_url"))
})

### Load Museums ##############################################################

europeana <- list(
  key = key$europeana, url = "https://www.europeana.eu/api/v2/",
  query = paste0("&query=what:(Painting+OR+Etching+OR+Drawing+OR+",
    "Woodcut+OR+Metalwork+OR+Furnishings+OR+Photograph+OR+Fotografie",
    "+OR+Ceramic+OR+Mosaic+OR+Glassware+OR+Bookplates+OR+Stillimage",
    "+OR+Zeichnung+OR+Rococo)&qf=TYPE:IMAGE"),
  reusability = "&reusability=open&reusability=restricted")

load_museums_intern <- {
  tryCatch({
    data <- readRDS("data/data_overview_intern.rds")
  }, error = function(e) {
    data <- data.frame(Museum = NA, Bestand = NA, 
      Table = NA, File = NA)[-1, ]
  })
}

load_museum_intern <- function(data_provider, file) {
  withProgress(message = "Museum wird geladen", value = 50, {
    try({
      file <- strsplit(file, " ")[[1]]
      data <- readRDS(file[1])
      
      colnames(data) <- gsub("...", " / ", colnames(data), fixed = TRUE)
      colnames(data) <- gsub(".", " ", colnames(data), fixed = TRUE)
      
      if (length(file) > 1) {
        data <- data[data[[file[2]]] %in% c(data_provider), ]
        data[[file[2]]] <- NULL
      }
    }, silent = TRUE)
  })
  
  return(data)
}

load_museums_extern <- {
  tryCatch({
    if (is.null(key$phpmyadmin$host)) {
      data <- readRDS("data/data_overview_extern.rds")[Museum != ""]
    } else {
      connect <- dbConnect(MySQL(), user = key$phpmyadmin$user, 
        password = key$phpmyadmin$password, dbname = key$phpmyadmin$dbname,
        host = key$phpmyadmin$host, port = key$phpmyadmin$port)
      query <- paste0("SELECT `edmDataProvider` AS Museum, count(id) AS Bestand ",
        "FROM `General_Europeana` GROUP BY `edmDataProvider`")
      data <- dbGetQuery(connect, query)
      dbDisconnect(connect)
      
      data <- data[data$Museum != "", ]
      data <- transform(data, Table = "General_Europeana")
    }
    
    transform(data, File = NA)
  }, error = function(e) {
    data.frame(Museum = NA, Bestand = NA, Table = NA, File = NA)[-1, ]
  })
}

load_museum_extern <- function(data_provider, table) {
  withProgress(message = "Museum wird geladen", value = 50, {
    data <- try({
      if (table == "General_Europeana") {
        column <- "edmDataProvider"
      }
      
      connect <- dbConnect(MySQL(), user = key$phpmyadmin$user, 
        password = key$phpmyadmin$password, dbname = key$phpmyadmin$dbname,
        host = key$phpmyadmin$host, port = key$phpmyadmin$port)
      query <- sprintf("SELECT * FROM `%s` WHERE `%s` = \"%s\"", 
        table, column, data_provider)
      data <- dbGetQuery(connect, query)
      dbDisconnect(connect)
      
      as.data.frame(data)
    }, silent = TRUE)
  })

  return(data)
}

load_museums <- reactiveValues(data = {
  data <- rbind(load_museums_intern, load_museums_extern)
  data <- transform(data, id = 1:nrow(data))
  
  transform(data, add = add_input(actionButton, id, 
    "add_load_museum_", label = "", icon = icon("plus-circle"), 
    onclick = paste0('Shiny.onInputChange(\"load_museum_button\", this.id);',
    dashboard_button_count, ' = ', dashboard_button_count, 
    ' + 1;', 'Shiny.onInputChange(\"load_museum_count\",', 
    dashboard_button_count, ')'), class = "red"))
})

load_museum <- function(data_provider) {
  file <- load_museums$data[Museum == data_provider]$File
  table <- load_museums$data[Museum == data_provider]$Table

  if (is.na(file)) {
    data <- load_museum_extern(data_provider, table)
  } else {
    data <- load_museum_intern(data_provider, file)
  }

  return(data)
}

observeEvent(input$delete_museum_confirm, {
  cat("delete museum\n")
  index <- gsub(".*museum_", "", input$load_museum_button)
  
  delete <- which(index == save_museums$id)
  save_museums$id <- save_museums$id[-delete]
  save_museums$names <- save_museums$names[-delete]
  save_museums$data <- save_museums$data[-delete]
  
  terms <- list(c("delete_", "add_"), 
                c("fa-minus", "fa-plus"), 
                c("lila ", "red "))
  load_museums$data[id == index]$add <- multiple_gsub(
    load_museums$data[id == index]$add, terms)
  
  filter_museums$load <- input$dashboard_load_search
  filter_museums$changed <- TRUE

  removeModal()
})

observeEvent(input$load_museum_count, {
  cat("add museum count\n")
  index <- gsub(".*museum_", "", input$load_museum_button)

  if (index %in% save_museums$id) {
    name <- save_museums$names[which(index == save_museums$id)]
    show_modal(paste0("Möchten Sie &bdquo;", name, "&ldquo; wirklich ",
      "aus der Liste der zu analysierenden Museen entfernen?"), 
      title = "Museum entfernen", confirm = TRUE, 
      button_name = "delete_museum_confirm")
  } else {
    cat("add museum\n")
    name <- load_museums$data[id == index]$Museum
    data <- load_museum(name)

    if (!("try-error" %in% class(data))) {
      save_museums$id <- c(save_museums$id, index)
      save_museums$names <- c(save_museums$names, name)
      save_museums$data[[length(save_museums$id)]] <- data
      
      terms <- list(c("add_", "delete_"), 
                    c("fa-plus", "fa-minus"), 
                    c("red ", "lila "))
      load_museums$data[id == index]$add <- multiple_gsub(
        load_museums$data[id == index]$add, terms)
      
      filter_museums$load <- input$dashboard_load_search
      filter_museums$changed <- TRUE
    } else {
      show_modal(paste0("Das ausgewählte Museum konnte nicht geladen werden. ",
        "Es trat folgender Fehler auf:"), error = data[1])
    }
  }
})

observeEvent(input$dashboard_load_reload, {
  if (!is.null(filter_museums$load) & filter_museums$changed) {
    shinyjs::runjs(paste0("change_dashboard_load_filter('", 
      filter_museums$load, "');"))
    
    filter_museums$changed <- FALSE
  }
}, priority = -1)

output$dashboard_load <- DT::renderDataTable({
  load_museums$data
}, rownames = FALSE, style = "bootstrap", escape = FALSE, 
  options = list(
    rowCallback = JS(
      "function(row, data, index, indexfull) {",
      "$('td:eq(0)', row).attr('title', data[0]);}"
    ),
    columnDefs = list(
      list(className = "dt-left", "targets" = 0), 
      list(className = "dt-right", "targets" = 5),
      list(targets = c(2, 3, 4), visible = FALSE),
      list(targets = 5, orderable = FALSE)
    ), 
    order = list(1, "desc")
  )
)

### Import Museums ##############################################################

add_own_museum <- function(data, name) {
  index <- which(grepl("own_", save_museums$id))
  index <- as.numeric(gsub("own_", "", save_museums$id[index]))
  index <- ifelse(length(index) == 0, 1, max(index) + 1)
  
  save_museums$id <- c(save_museums$id, paste0("own_", index))
  save_museums$names <- c(save_museums$names, name)
  save_museums$data[[length(save_museums$id)]] <- data
}

read_data <- function(file, data = NULL) {
  message <- customTryCatch({
    if (tolower(strsplit(file$name, "\\.")[[1]][-1]) == "rds") {
      data <- readRDS(file$datapath)
    } else {
      encoding <- guess_encoding(file$datapath, n_max = -1)$encoding[1]
      header <- as.logical(input$dashboard_import_file_header)
      
      if (!(encoding %in% c("unknown", "UTF-8", "Latin-1")))
        encoding <- "unknown"

      sep <- input$dashboard_import_file_sep
      if (sep == "") sep <- "auto"
      
      quote <- input$dashboard_import_file_quote
      if (quote == "") quote <- "\""
      
      data <- fread(file = file$datapath, sep = sep, header = header, 
        encoding = encoding, quote = quote, na.strings = c("NA", "", "na"), 
        data.table = FALSE, verbose = FALSE, showProgress = FALSE)
    }
    
    if (is.null(attr(data, "type"))) {
      data <- as.data.frame(data)
    }
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste0("Die ausgewählte Datei konnte nicht ",
      "eingelesen werden. Es trat folgender Fehler auf:"), 
      error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste0("Beim Einlesen der ausgewählten Datei ",
      "trat folgende Warnung auf:"), title = "Warnung", 
      error = capture.output(message$warning))
  }
  
  if (class(message$error)[1] == "NULL")
    message$error <- message$warning
  
  return(list(data = data, error = class(message$error)))
}

observeEvent(input$dashboard_import_name, {
  if (nchar(input$dashboard_import_name) > 0) {
    shinyjs::enable("dashboard-import-file")
  } else {
    shinyjs::disable("dashboard-import-file")
  }
})

observeEvent(input$dashboard_import_progress_bar, {
  req_and_assign(input$dashboard_import_progress_bar, "progress_bar")
  import_file_name <- tolower(strsplit(progress_bar, "\\.")[[1]][-1])
  
  if (length(import_file_name) == 0) import_file_name <- "none"
  
  if (import_file_name %in% c("txt", "rds", "csv")) {
    progress <- shiny::Progress$new()
    progress$set(message = "Museum wird eingelesen", value = 50)
    
    progress_museums$object <- progress
  }
  
  if (progress_bar == "Maximum upload size exceeded") {
    if (!is.null(progress_museums$object)) {
      progress_museums$object$close()
      progress_museums$object <- NULL
    }
    
    show_modal(paste("Die ausgewählte Datei ist zu groß und kann",
      "nicht eingelesen werden. Die maximale Dateigröße beträgt", 
      max_file_size, "MB."))
  }
  
  if (progress_bar == "Upload complete") {
    if (!is.null(progress_museums$object)) {
      progress_museums$object$close()
      progress_museums$object <- NULL
    }
    
    shinyjs::enable("dashboard_import_button")
  } else {
    shinyjs::disable("dashboard_import_button")
  }
})

observeEvent(input$dashboard_import_file, {
  req_and_assign(input$dashboard_import_file, "file")
  
  if (tolower(strsplit(file$name, "\\.")[[1]][-1]) == "rds") {
    shinyjs::hide("dashboard-import-input")
  } else {
    shinyjs::show("dashboard-import-input")
  }
})

observeEvent(input$update_museum_confirm, {
  cat("update museum\n")
  
  req_and_assign(input$dashboard_import_file, "file")
  req_and_assign(input$dashboard_import_name, "name")
  
  progress <- shiny::Progress$new()
  progress$set(message = "Museum wird importiert", value = 50)
  on.exit(progress$close())

  result <- read_data(file)

  if (!is.null(result$data)) {
    save_museums$data[[which(name == save_museums$names)]] <- result$data
    index <- save_museums$id[which(name == save_museums$names)]

    if (length(index) == 1) {
      ids <- c(which(index == preprocess_museums$id),
               which(index == names(preprocess_history$data)))
      
      attr(result$data, "select") <- 1:nrow(result$data)
      
      preprocess_museums$data[[ids[1]]] <- result$data
      preprocess_history$active[ids[2]] <- 0
    }
  }
  
  if (result$error[1] == "NULL") {
    removeModal()
  }
})

observeEvent(input$dashboard_import_button, {
  req_and_assign(input$dashboard_import_file, "file")
  req_and_assign(input$dashboard_import_name, "name")
  
  if (!is.null(file)) {
    saved <- FALSE

    if (name %in% save_museums$names) {
      show_modal(paste0("Es existiert bereits ein Museum mit dem Namen ",
        "&bdquo;", name, "&ldquo;. Möchten Sie es aktualisieren?"), 
        title = "Museum aktualisieren", confirm = TRUE, 
        button_name = "update_museum_confirm")
      
      saved <- TRUE
    } else {
      progress <- shiny::Progress$new()
      progress$set(message = "Museum wird importiert", value = 50)
      on.exit(progress$close())
      
      result <- read_data(file)

      if (!is.null(result$data) & !("error" %in% result$error)) {
        cat("add own museum\n")
        
        add_own_museum(result$data, name)
        saved <- TRUE
      }
    }
    
    if (saved) {
      import_museums$file <- input$dashboard_import_file$datapath
      import_museums$header <- input$dashboard_import_file_header
      import_museums$sep <- input$dashboard_import_file_sep
    }
  }
})

observe({
  index <- which(grepl("own_", save_museums$id))

  if (length(index) > 0) {
    shinyjs::show(id = "dashboard-import-table")
    count <- lapply(save_museums$data[index], nrow)
    ids <- as.numeric(gsub("own_", "", save_museums$id[index]))

    import_museums$data <- data.frame(
      Museum = save_museums$names[index], Bestand = unlist(count), 
      id = save_museums$id[index], add = add_input(actionButton, ids, 
        "delete_load_museum_own_", label = "", icon = icon("minus-circle"), 
        onclick = paste0('Shiny.onInputChange(\"load_museum_button\", this.id);',
          dashboard_button_count, ' = ', dashboard_button_count, ' + 1;', 
          'Shiny.onInputChange(\"load_museum_count\",', 
          dashboard_button_count, ')'), class = "lila")
    )
  } else {
    shinyjs::hide(id = "dashboard-import-table")
  }
})

output$dashboard_import <- DT::renderDataTable({
  datatable(import_museums$data, 
    rownames = FALSE, style = "bootstrap", 
    escape = FALSE, options = list(
      rowCallback = JS(
        "function(row, data, index, indexfull) {",
        "$('td:eq(0)', row).attr('title', data[0]);}"
      ),
      columnDefs = list(
        list(className = "dt-left", "targets" = 0), 
        list(className = "dt-right", "targets" = 3),
        list(targets = 2, visible = FALSE),
        list(targets = 3, orderable = FALSE)
      ), 
      pageLength = 4)) %>% 
    formatCurrency(columns = "Bestand", mark = ".", 
      digits = 0, currency = "")
})

### Example ###################################################################

transform_date <- function(x) {
  x <- stri_extract_all(x, regex = "[1-2][0-9]{3}")
  
  return(round(mean(as.numeric(x[[1]])), 0))
}

output$dashboard_example <- renderHighchart({
  data <- as.data.table(readRDS("data/pinakothek.rds"))
  data <- data[grepl("Pinakothek", Bestand)][order(Bestand)]
  data[, Datierung := sapply(Datierung, transform_date, USE.NAMES = FALSE)]

  histograms <- list(
    get_histogram(data[Bestand == unique(data$Bestand)[1]]$Datierung),
    get_histogram(data[Bestand == unique(data$Bestand)[2]]$Datierung),
    get_histogram(data[Bestand == unique(data$Bestand)[3]]$Datierung)
  )
  
  labels <- paste("zwischen", seq(1300, 2020, 10), 
    "und", seq(1300, 2020, 10)[-1])

  highchart() %>%
    hc_xAxis(categories = labels[-length(labels)]) %>% 
    hc_plotOptions(column = list(stacking = "normal", borderWidth = 0.25,
      groupPadding = 0.01, pointPadding = 0)) %>%
    hc_add_series(data = histograms[[1]], name = "Alte Pinakothek",
      type = "column", color = "#cd3a56") %>%
    hc_add_series(data = histograms[[2]], name = "Neue Pinakothek",
      type = "column", color = "#953269") %>%
    hc_add_series(data = histograms[[3]], name = "Pinakothek der Moderne",
      type = "column", color = "#553084") %>%
    hc_legend(align = "top", verticalAlign = "top", x = 13, y = 75) %>%
    hc_yAxis(lineWidth = 0, minorGridLineWidth = 0, labels = list()) %>%
    hc_xAxis(lineWidth = 0, gridLineWidth = 0,
      minorGridLineWidth = 0, labels = list(), tickLength = 0) %>%
    hc_tooltip(useHTML = TRUE, backgroundColor = NULL, shadow = FALSE, 
      formatter = JS("function(){return('<div style=\"background-color:' + 
      this.series.color + '\" class=\"tooltip-hc\">Die ' + this.series.name +
      ' hat ' + this.y + ' Objekte <br>' + this.x + '</div>')}")) %>%
    hc_add_theme(hc_theme_max)
})