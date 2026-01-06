### General ###################################################################

preprocess_button_count <- '$(\".wrapper\").data(\"history\").count'
preprocess_museums <- reactiveValues(data = list(), id = NULL, names = NULL)
preprocess_history <- reactiveValues(data = list(), active = NULL)

preprocess_cell_edits <- reactiveValues(data = list())
preprocess_selected_history <- reactiveValues(data = NULL, load = FALSE)

updateSelectInput(session, "preprocessing_select_operation", select = "")

shinyjs::disable("preprocessing_execute_button")
shinyjs::hide("preprocessing_all_museums_check")
shinyjs::hide("preprocessing_export_button")

preprocess_operations <- {
  list(
    "yesfilter"  = list(category = "row", run = "apply_filter"),
    "lastfilter" = list(category = "row", run = "apply_filter"),
    "nofilter"   = list(category = "row", run = "apply_filter"),
    "duplicate"  = list(category = "row", run = "apply_remove_duplicates",
                     min_columns = 1),
    
    "ctype"      = list(category = "column", run = "apply_column_type",
                     check = TRUE, min_columns = 1, text = "select"),
    "cname"      = list(category = "column", run = "apply_column_name", 
                     min_columns = 1),
    "cpaste"     = list(category = "column", run = "apply_column_paste",
                     single_name = TRUE, min_columns = 2, text = "text"),
    "cseparate"  = list(category = "column", run = "apply_column_separate",
                     min_columns = 1, text = "text"),
    "cdelete"    = list(category = "column", run = "apply_column_delete",
                     min_columns = 0, text = "slider"),
    
    "cedit"      = list(category = "cell", run = "apply_cell_edit"),
    "cgsub"      = list(category = "cell", run = "apply_column_gsub", 
                     min_columns = 1, text = "textArea"),
    
    "copy"       = list(category = "museum", run = "apply_museum_copy", 
                     text = "text"),
    "export"     = list(category = "museum", run = "button",
                     text = "select"),
    
    "rcode"      = list(run = "apply_rcode", text = "textArea"),
    "regex"      = list(run = "apply_regex", min_columns = 1, text = "text"),
    "aggreg"     = list(run = "apply_column_aggregate", min_columns = 2, 
                     text = "select")
  )
}

### Videos ####################################################################

observeEvent(input$preprocessing_history_video, {
  show_video(get("preprocessing_history_video_url"))
})

observeEvent(input$preprocessing_video, {
  operation <- input$preprocessing_select_operation
  video_url <- paste("preprocessing", operation, "video_url", sep = "_")
  
  if (exists(video_url)) {
    show_video(get(video_url))
  }
})

### Functions #################################################################

exclude_id_from_data <- function(data, id) {
  if (length(data) > 0) {
    id_remove <- which(id == names(data))
    
    if (length(id_remove) == 1) {
      data[[id]] <- NULL
    }
  }
  
  return(data)
}

active_filters <- function(history, active) {
  active <- as.integer(active)
  filters <- list()

  if (active > 0) {
    for (i in seq(active)) {
      filters <- active_filter(history[[i]], filters)
    }
  }
  
  return(filters)
}

active_filter <- function(entry, filters) {
  if (grepl("filter", entry$operation)) {
    if (entry$operation == "yesfilter") {
      filters[[length(filters) + 1]] <- entry
    }
    
    if (entry$operation == "lastfilter") {
      filters[[length(filters)]] <- NULL
    }
    
    if (entry$operation == "nofilter") {
      filters <- list()
    }
  }
  
  return(filters)
}

last_filter <- function(filters) {
  filter <- filters[[length(filters)]]$filter
  row <- NULL
  
  if (length(filters) > 1) {
    row <- filters[[length(filters) - 1]]$row
  }
  
  return(list("filter" = filter, "row" = row))
}

load_history <- function(id_museum, id_history, data, 
    modify = FALSE, replace = TRUE) {
  progress <- shiny::Progress$new()
  on.exit(progress$close())
  progress$set(message = "Historie wird geladen", value = 50)
  
  history <- data[id_history][[1]]

  # remove operations of type "cedit"
  if (modify) {
    new_history <- list()
    
    for (entry in history) {
      if (entry$operation != "cedit") {
        new_history[[length(new_history) + 1]] <- entry
      }
    }
    
    history <- new_history
  }
  
  if (!replace) {
    old_history <- preprocess_history$data[id_museum][[1]]
    history <- append(old_history, history)
  }
  
  preprocess_history$data[id_museum][[1]] <- history
  index <- which(names(preprocess_history$data) == id_museum)
  active <- preprocess_history$active[index]
  
  if (replace | is.null(active)) {
    preprocess_history$active[index] <- 0
  }
  
  if (replace) {
    id <- which(preprocess_museums$id == id_museum)
    data <- preprocess_museums$data[[id]]
    data <- apply_reverse(data)$data
    
    preprocess_museums$data[[id]] <- data
  }

  preprocess_selected_history$data <- NULL
    
  show_modal("Die Historie wurde erfolgreich geladen.", 
    title = "Benachrichtigung")
}

apply_filter <- function(data, filter = NULL, row = NULL, multiple = FALSE) {
  pre <- prettify_number(length(attr(data, "select")))

  message <- customTryCatch({
    if (is.null(row)) {
      row <- 1:nrow(data)
    } else if (multiple) {
      row <- attr(data, "select")

      if (length(row) > 0) {
        new_row <- convert_filters(data[row, ], filter)
        row <- row[new_row]
      }
    }
  
    attr(data, "select") <- row
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Die Zeilen konnten nicht gefiltert werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal("Beim Filtern der Zeilen trat folgende Warnung auf:", 
      title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal(paste0("Das Museum wies bislang ", pre, " Beobachtungen ",
      "auf. Es wurden ", prettify_number(length(attr(data, "select"))),
      " Zeilen gefiltert."), title = "Benachrichtigung")
  }
  
  return(list(data = data, error = NULL, name = NULL))
}

convert_filters <- function(data, filters) {
  data$uEip2gWLBv <- 1:nrow(data)
  string <- list(global = NULL, local = NULL)
  
  for (i in seq_along(filters)) {
    filter <- convert_filter(filters[i], data)
    
    if (names(filters)[i] == "Global") {
      string$global <- filter
    } else {
      string$local <- c(string$local, filter)
    }
  }
  
  string$local <- paste(string$local, collapse = " & ")
  string$local <- paste0("filter(", string$local, ")")
  
  if (!is.null(string$global)) {
    string$global <- paste0("filter_all(", string$global, ")")
    string$local <- paste(string$global, "%>%", string$local)
  }
  
  string <- paste("data %>%", string$local)
  result <- eval(parse(text = string))
  row <- result$uEip2gWLBv
  
  return(row)
}

convert_filter <- function(filter, data) {
  column <- names(filter)
  filter <- unname(filter)
  
  test <- which(colnames(data) == column)
  test <- data[, test, drop = TRUE]

  # numeric
  if (is.numeric(test)) {
    string <- strsplit(filter, " ... ")[[1]]
    string <- paste0("`", column, "` >= ", string[1], 
      " & `", column, "` <= ", string[2])
    
    return(string)
  }
  
  # factor
  if (is.factor(test)) {
    string <- str_replace(filter, "\\[", "c(")
    string <- str_replace(string, "\\]", ")")
    string <- paste0("`", column, "` %in% ", string)
    
    return(string)
  }
  
  # character
  string <- paste0("regex(\"", filter, "\", ignore_case = TRUE)")
  
  if (column == "Global") {
    string <- paste0("any_vars(str_detect(., ", string, "))")
  } else {
    string <- paste0("str_detect(`", column, "`, ", string, ")")
  }
  
  return(string)
}

apply_remove_duplicates <- function(data, column) {
  pre <- prettify_number(length(attr(data, "select")))
  
  message <- customTryCatch({
    select <- attr(data, "select")
    ids <- which(colnames(data) %in% column)

    if (length(ids) == length(column)) {
      check <- !duplicated(data[select, ids])
      select <- select[check]
    }

    attr(data, "select") <- select
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Die Zeilen konnten nicht gefiltert werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal("Beim Filtern der Zeilen trat folgende Warnung auf:", 
      title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal(paste0("Das Museum wies bislang ", pre, " Beobachtungen ",
      "auf. Es wurden ", prettify_number(length(attr(data, "select"))),
      " Zeilen gefiltert."), title = "Benachrichtigung")
  }
  
  return(list(data = data, error = NULL, name = NULL))
}

apply_column_type <- function(data, column, text, name) {
  message <- customTryCatch({
    select <- attr(data, "select")
    ids <- which(colnames(data) %in% column)
    
    if (length(ids) == length(column)) {
      result <- lapply(data[ids], eval(parse(text = paste0("as.", text))))
      result <- as.data.frame(result, stringsAsFactors = FALSE)
      changes <- get_changes(ids, data, result, select)
  
      if (is.null(name)) {
        data[, ids] <- result
      } else {
        data <- cbind(data, result, stringsAsFactors = FALSE)
        name <- check_colnames(name, colnames(data))
        colnames(data)[(ncol(data) + 1 - length(column)):ncol(data)] <- name
      }
    } else {
      changes <- c(0, 0)
    }
    
    attr(data, "select") <- select
  })

  if ("error" %in% class(message$error)) {
    show_modal(paste("Der ausgewählte Spaltentyp konnte nicht geändert werden.",
      "Es trat folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste("Es wurden", changes[1], "Zeilen geändert.",
      "Dabei sind", changes[2], "fehlende Werte entstanden.",
      "Beim Ändern des Spaltentyps trat folgende Warnung auf:"), 
      title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal(paste("Es wurden", changes[1], "Zeilen",
      "geändert. Dabei sind", changes[2], "fehlende Werte",
      "entstanden."), title = "Benachrichtigung")
  }

  return(list(data = data, error = class(message$error), name = name))
}

apply_column_name <- function(data, column, name) {
  message <- customTryCatch({
    select <- attr(data, "select")
    text <- strsplit(name, "\n")[[1]]
    count <- 0
    
    if (length(which(colnames(data) %in% column)) == length(column)) {
      for (i in seq(length(column))) {
        id <- which(column[i] == colnames(data))
        text[i] <- gsub('\"', "", text[i], fixed = TRUE)
  
        if (!is.na(text[i]) & nchar(text[i]) > 0 & 
            !(text[i] %in% colnames(data))) {
          colnames(data)[id] <- text[i]
          count <- count + 1
        }
      }
    }

    attr(data, "select") <- select
  })

  if (count != 1) {
    message_text <- paste0("Es wurden ", count, " Spaltennamen geändert. ")
  } else {
    message_text <- paste0("Es wurde ", count, " Spaltenname geändert. ")
  }
  
  if (count != length(column)) {
    message_text <- paste0(message_text, "Doppelte Spaltennamen dürfen ",
      "nicht vergeben werden. Ein Spaltenname darf kein Backslash enthalten. ")
  }
  
  if ("error" %in% class(message$error)) {
    show_modal(paste0("Die ausgewählten Spalten konnten nicht geändert werden. ",
      "Es trat folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste0(message_text, "Beim Ändern der Spaltennamen trat folgende ",
      "Warnung auf:"), title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal(message_text, title = "Benachrichtigung")
  }
  
  return(list(data = data, error = class(message$error), name = name))
}

apply_column_paste <- function(data, column, text, name) {
  message <- customTryCatch({
    select <- attr(data, "select")
    
    if (length(which(colnames(data) %in% column)) == length(column)) {
      name <- check_colnames(name, colnames(data))
      data <- as.data.frame(unite(data = data, col = !!name, 
        column, sep = text, remove = FALSE))
      
      data[[name]] <- gsub(paste0("NA", text), "", data[[name]], fixed = TRUE)
      data[[name]] <- gsub("NA", "", data[[name]], fixed = TRUE)
    }

    attr(data, "select") <- select
  })

  if ("error" %in% class(message$error)) {
    show_modal(paste0("Die Spalten konnten nicht vereint werden. Es trat ",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste0("Beim Vereinen der Spalten trat folgende Warnung ",
      "auf:"), title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal("Die ausgewählten Spalten wurden erfolgreich vereint.", 
      title = "Benachrichtigung")
  }
  
  return(list(data = data, error = class(message$error), name = name))
}

apply_column_separate <- function(data, column, text, vertical) {
  message <- customTryCatch({
    select <- attr(data, "select")
    
    # create pseudo-content as last column
    data$uEip2gWLBv <- TRUE
    
    if (length(which(colnames(data) %in% column)) == length(column)) {
      for (index in seq(length(column))) {
        id <- which(column[index] == colnames(data))
        result <- strsplit(as.character(data[, id]), text)
        
        length <- sapply(result, length)
        
        if (vertical) {
          data$uEip2gWLBv <- seq_len(nrow(data))
          
          data <- data[rep(seq_len(nrow(data)), length), 1:ncol(data)]
          data[[id]] <- unlist(result)
          
          select <- seq_len(nrow(data))[data$uEip2gWLBv %in% select]
          length <- max(length)
        } else {
          length <- max(length)
    
          if (length > 1) {
            result <- sapply(result, function(x){ c(x, rep(NA, length - length(x)))})
    
            data <- cbind(data[, 1:id, drop = FALSE], t(result), 
              data[, (id + 1):ncol(data), drop = FALSE], stringsAsFactors = FALSE)
            name <- paste(colnames(data)[id], 1:length, sep = "_")
            name <- sapply(name, check_colnames, colnames(data))
            colnames(data)[(id + 1):(id + length)] <- name
          }
        }
      }
    } else {
      length <- 0
    }

    attr(data, "select") <- select
    data$uEip2gWLBv <- NULL
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Die Spalten konnten nicht getrennt werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal("Beim Trennen der Spalten trat folgende Warnung auf:", 
      title = "Warnung", error = capture.output(message$warning))
  } else {
    if (length > 1) {
      show_modal("Die ausgewählten Spalten wurden erfolgreich getrennt.", 
        title = "Benachrichtigung")
    } else {
      show_modal(paste("Die Spalten wurden nicht getrennt. Die Spalten oder",
        "das Trennzeichen wurde nicht gefunden."), title = "Benachrichtigung")
    }
  }
  
  return(list(data = data, error = class(message$error), name = NULL))
}

apply_column_delete <- function(data, column, text) {
  counter <- 0
  
  message <- customTryCatch({
    select <- attr(data, "select")
    counter <- ncol(data)
    
    for (name in column) {
      if (name %in% colnames(data)) {
        data[[name]] <- NULL
      }
    }
    
    if (!is.na(text)) {
      if (text > 0) {
        counter <- ncol(data)
        indices <- data == "-" | data == "" | is.na(data)
        data <- data[, which(colMeans(indices) <= (text / 100))]
      }
    }
    
    counter <- counter - ncol(data)
    attr(data, "select") <- select
  })

  if (counter == 1) {
    message <- c("wurde", "Spalte")
  } else {
    message <- c("wurden", "Spalten")
  }
  
  show_modal(paste("Es", message[1], counter, message[2], 
    "gelöscht."), title = "Benachrichtigung")

  return(list(data = data, error = NULL, name = NULL))
}

apply_column_gsub <- function(data, column, text) {
  message <- customTryCatch({
    select <- attr(data, "select")
    text <- strsplit(text, "\n")[[1]]
    
    if (length(which(colnames(data) %in% column)) == length(column)) {
      for (index in seq(length(column))) {
        id <- which(column[index] == colnames(data))
        
        for (t in text) {
          t <- strsplit(t, " = ")[[1]]
          if (length(t) == 1) t[2] <- ""
          
          data[[id]] <- gsub(t[1], t[2], data[[id]], ignore.case = TRUE)
        }
      }
    }
    
    attr(data, "select") <- select
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Die Zeichenfolgen konnten nicht ersetzt werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste("Beim Ersetzen der Zeichenfolgen trat folgende Warnung",
      "auf:"), title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal("Die Zeichenfolgen wurden erfolgreich ersetzt.", 
      title = "Benachrichtigung")
  }
  
  return(list(data = data, error = class(message$error), name = NULL))
}

apply_column_aggregate <- function(data, column, text) {
  message <- customTryCatch({
    data <- data[attr(data, "select"), ]
    
    columns <- paste0("data$`", column, "`")
    remove <- ifelse(text == "NROW", "", ", na.rm = TRUE")
    data <- eval(parse(text = paste0("aggregate(", columns[1], 
      ", by = list(", paste0(columns[-1], collapse = ", "), 
      "), FUN = ", text, remove, ")")))

    colnames(data)[1:(ncol(data) - 1)] <- column[-1]
    colnames(data)[ncol(data)] <- "Werte"

    attr(data, "select") <- 1:nrow(data)
  })
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Die Spalten konnten nicht aggregiert werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste("Beim Aggregieren der Spalten trat folgende Warnung",
      "auf:"), title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal("Die ausgewählten Spalten wurden erfolgreich aggregiert.", 
      title = "Benachrichtigung")
  }
  
  return(list(data = data, error = class(message$error), name = NULL))
}

apply_cell_edit <- function(data, edit = NULL) {
  select <- attr(data, "select")
  
  for (cell in edit) {
    data[select[cell$row], cell$col + 1] <- cell$value
  }
  
  attr(data, "select") <- select

  if (length(edit) == 1) {
    message <- c("wurde ", " Zelle")
  } else {
    message <- c("wurden ", " Zellen")
  }
  
  show_modal(paste0("Es ", message[1], prettify_number(length(edit)),
    message[2], " geändert."), title = "Benachrichtigung")
  
  return(list(data = data, error = NULL, name = NULL))
}

apply_regex <- function(data, column, text) {
  select <- attr(data, "select")
  
  message <- customTryCatch({
    if (length(which(colnames(data) %in% column)) == length(column)) {
      for (index in seq(length(column))) {
        id <- which(column[index] == colnames(data))
        
        result <- sapply(id, apply_regex_single, data = data, text = text)
        length <- max(sapply(result, length))

        if (length > 1) {
          result <- t(sapply(result, function(x){ 
            c(x, rep(NA, length - length(x)))}))

          # define maximum number of columns
          length <- min(length, 50)
          result <- result[, 1:length, drop = FALSE]
        } else {
          result <- unlist(result)
          result <- matrix(result, nrow = length(result), ncol = 1)
        }
          
        data <- cbind(data[, 1:id, drop = FALSE], result, 
          data[, (id + 1):ncol(data), drop = FALSE], 
          stringsAsFactors = FALSE)
        name <- paste(colnames(data)[id], 1:length, sep = "_")
        name <- sapply(name, check_colnames, colnames(data))
        colnames(data)[(id + 1):(id + length)] <- name
      }
    } else {
      length <- 0
    }
  })
  
  attr(data, "select") <- select
  
  if ("error" %in% class(message$error)) {
    show_modal(paste("Der reguläre Ausdruck konnte nicht angewendet werden. Es",
      "trat folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste("Beim Anwenden des regulären Ausdrucks trat folgende",
      "Warnung auf:"), title = "Warnung", error = capture.output(message$warning))
  } else {
    if (length > 0) {
      show_modal("Der reguläre Ausdruck wurde erfolgreich angewendet.", 
        title = "Benachrichtigung")
    } else {
      show_modal(paste("Der reguläre Ausdruck konnte nicht angewendet werden.",
        "Die Spalten wurden nicht gefunden."), title = "Benachrichtigung")
    }
  }
  
  return(list(data = data, error = class(message$error), name = NULL))
}

apply_regex_single <- function(x, data, text) {
  return(stringr::str_extract_all(data[, x, drop = TRUE], text))
}

apply_rcode <- function(data, text) {
  # runs twice to generate correct output based on filtered rows
  messages <- list()
  notice <- NULL
  
  message <- customTryCatch({
    select <- attr(data, "select")
    lines <- strsplit(text, "\n")[[1]]
    
    for (i in seq(length(lines))) {
      eval(parse(text = lines[i]))
    }
    
    original <- data
    data <- data[select, , drop = FALSE]
    
    for (i in seq(length(lines))) {
      messages[[i]] <- capture.output(eval(parse(text = lines[i])))
      messages[[i]] <- messages[[i]][messages[[i]] != ""]
      messages[[i]] <- paste(messages[[i]], collapse = "<br />")
    }
    
    messages <- unlist(messages)
    messages <- paste(messages, collapse = "<br />")
    
    if (nrow(data) != length(select)) {
      select <- 1:nrow(data)
    }
      
    data <- original
    attr(data, "select") <- select
  })

  if (length(messages) > 0) {
    if (nchar(messages) > 0) {
      notice <- " Dabei ist der folgende Output entstanden:"
    }
  }

  if ("error" %in% class(message$error)) {
    show_modal(paste("Der R-Code konnte nicht angewendet werden. Es trat",
      "folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal("Beim Anwenden des R-Codes trat folgende Warnung auf:", 
      title = "Warnung", error = capture.output(message$warning))
  } else {
    show_modal(paste0("Der R-Code wurde erfolgreich angewendet.", notice), 
      title = "Benachrichtigung", error = messages)
  }
  
  return(list(data = data, error = class(message$error), name = NULL))
}

apply_museum_copy <- function(data, text) {
  if (!(text %in% save_museums$names)) {
    select <- attr(data, "select")
    add_own_museum(data[select, , drop = FALSE], text)

    show_modal("Das Museum wurde erfolgreich kopiert.",
      title = "Benachrichtigung")
  } else {
    show_modal(paste("Das Museum konnte nicht kopiert werden. Ein",
      "Museum mit diesem Namen besteht bereits."), title = "Fehler")
  }

  return(list(data = data, error = NULL, name = NULL))
}

apply_museum_merge <- function(data, museum, text) {
  if (!(text %in% save_museums$names)) {
    columns <- vector()
    data_all <- NULL
    
    for (id in museum) {
      if (id %in% preprocess_museums$id) {
        data_single <- preprocess_museums$data[[which(preprocess_museums$id == id)]]
        data_single <- data_single[attr(data_single, "select"), , drop = FALSE]
      } else {
        data_single <- save_museums$data[[which(save_museums$id == id)]]
      }
      
      if (is.null(data_all)) {
        data_all <- data_single
      } else {
        columns <- intersect(colnames(data_all), colnames(data_single))
        if (length(columns) < 1) break
        
        data_all <- rbind(data_all[, columns], data_single[, columns])
      }
    }
    
    if (length(columns) > 0) {
      add_own_museum(data_all, text)

      show_modal("Die Museen wurden erfolgreich zusammengeführt.",
        title = "Benachrichtigung")
    } else {
      show_modal(paste("Die Museen konnten nicht zusammengeführt werden.",
        "Es gibt keine gemeinsamen Spalten."), title = "Fehler")
    }
  } else {
    show_modal(paste("Die Museen konnten nicht zusammengeführt werden. Ein",
      "Museum mit diesem Namen besteht bereits."), title = "Fehler")
  }
  
  return(list(data = data, error = NULL, name = NULL))
}

apply_reverse <- function(data) {
  req_and_assign(input$preprocessing_select_museum, "id_preprocess")
  id_original <- which(save_museums$id == id_preprocess)
  
  data <- save_museums$data[[id_original]]
  attr(data, "select") <- 1:nrow(data)
  
  show_modal(paste("Die Änderungen am ausgewählten Museum wurden",
    "erfolgreich zurückgesetzt."), title = "Benachrichtigung")

  return(list(data = data, error = NULL, name = NULL))
}

get_changes <- function(ids, x, y, select) {
  changes <- sapply(1:length(ids), get_changes_single, 
    x = x, y = y, select = select, simplify = FALSE)
  changes <- trimws(prettify_number(unlist(changes)))

  if (length(ids) > 1) {
    changes <- c(nrow(x), paste(paste(changes[-length(changes)], 
      collapse = ", "), changes[length(changes)], sep = " und "))
  } else {
    changes <- c(nrow(x), changes[1])
  }
  
  changes[1] <- prettify_number(as.integer(changes[1]))

  return(changes)
}

get_changes_single <- function(column, x, y, select) {
  return(length(setdiff(which(is.na(y[select, column])), 
    which(is.na(x[select, column])))))
}

check_colnames <- function(name, colnames) {
  name <- strsplit(name, "\n")[[1]]
  
  for (i in seq(length(name))) {
    name[i] <- gsub("\\", "", name[i], fixed = TRUE)
    if (nchar(name[i]) == 0) name[i] <- "Neue Spalte"
    name[i] <- check_colnames_single(name[i], colnames)
  }
  
  return(name)
}

check_colnames_single <- function(name, colnames) {
  if (name %in% colnames) {
    name <- check_colnames_single(paste(name, "1"), colnames)
  } else {
    return(name)
  }
}

get_operation_name <- function(name) {
  subname <- try({get(paste("preprocessing", name, 
    "name", sep = "_"))}, silent = TRUE)
  
  if ("try-error" %in% class(subname)) {
    subname <- name
  }
  
  names(name) <- subname
  
  return(name)
}

get_fields <- function(fields) {
  if (fields != "button") {
    fields <- as.list(args(eval(parse(text = fields))))
  } else {
    fields <- NULL
  }
  
  return(fields)
}

### User Interface Elements ###################################################

general_modal <- function() {
  title = "Historie bearbeiten"
  text = "Möchten Sie eine Historie laden oder die Historie speichern?"
  footer <- tagList(modalButton(icon("times")), 
    fileInput("preprocessing_load_history_button", NULL,
      accept = c(".rds"), buttonLabel = "Laden"),
    downloadButton("preprocessing_save_history_button", "Speichern"))
  
  showModal(div(class = "confirm", modalDialog(title = title, 
    HTML(text), easyClose = TRUE, size = "s", footer = footer)))
}

special_modal <- function(data) {
  labels <- attr(data, "labels")
  labels <- setNames(names(data), labels)
  
  text <- tagList(
    selectInput("preprocessing_select_history", 
      "Welche Historie möchten Sie auswählen?", labels),
    checkboxInput("preprocessing_modify_history", 
      "Änderungen an einzelnen Zellen ausschließen", TRUE),
    checkboxInput("preprocessing_replace_history", 
      "Bisherige Historie ersetzen", TRUE)
  )
  
  title <- "Historie bearbeiten"
  select_name <- "preprocessing_select_history_button"
  abort_name <- "preprocessing_abort_history_button"
  
  footer <- tagList(modalButton(icon("times")), 
    actionButton(select_name, "Auswählen"), 
    actionButton(abort_name, "Abbrechen"))
  
  showModal(div(class = "confirm", modalDialog(title = title, 
    text, easyClose = TRUE, size = "s", footer = footer)))
}

merge_modal <- function() {
  museums <- save_museums$id
  names(museums) <- save_museums$names
  
  if (length(museums) == 0) {
    museums <- c("Bitte importieren Sie zunächst ein Museum" = "")
  }
  
  text <- tagList(
    selectInput("preprocessing_merge_museum_names", 
      "Museen auswählen", choices = museums, multiple = TRUE),
    uiOutput("preprocessing_merge_operation")
  )

  title = "Museen zusammenführen"
  select_name <- "preprocessing_select_merge_button"

  footer <- tagList(modalButton(icon("times")), 
    actionButton(select_name, "Auswählen"), 
    modalButton("Abbrechen"))
  
  showModal(div(class = "confirm", modalDialog(title = title, 
    text, easyClose = TRUE, size = "s", footer = footer)))
}

output$preprocessing_merge_operation <- renderUI({
  if (length(input$preprocessing_merge_museum_names) > 1) {
    tag_list <- tagList(
      textInput("preprocessing_merge_museum_text", "Museumsname")
    )
  } else {
    tag_list <- tagList(
      div(id = "preprocessing_merge_filler")
    )
  }
  
  return(tag_list)
})

observe({
  museums <- save_museums$id
  names(museums) <- save_museums$names

  if (length(museums) > 0) {
    shinyjs::enable("preprocessing_select_museum")
    updateSelectInput(session, "preprocessing_select_museum", 
      choices = museums)
    shinyjs::show("preprocessing-history")
  } else {
    shinyjs::hide("preprocessing-history")
    updateSelectInput(session, "preprocessing_select_museum", 
      choices = c("Bitte importieren Sie zunächst ein Museum" = ""))
    shinyjs::disable("preprocessing_select_museum")
  }
  
  isolate({
    if (length(setdiff(preprocess_museums$id, museums)) > 0) {
      for (index in setdiff(preprocess_museums$id, museums)) {
        delete <- which(index == preprocess_museums$id)
        
        preprocess_museums$id <- preprocess_museums$id[-delete]
        preprocess_museums$names <- preprocess_museums$names[-delete]
        preprocess_museums$data <- preprocess_museums$data[-delete]
        
        preprocess_history$data <- preprocess_history$data[-delete]
        preprocess_history$active <- preprocess_history$active[-delete]
      }
    }
  })
})

observe({
  req_and_assign(input$preprocessing_select_operation, "operation")
  
  if (operation == "export") {
    shinyjs::hide("preprocessing_execute_button")
    shinyjs::show("preprocessing_export_button")
  } else {
    shinyjs::hide("preprocessing_export_button")
    shinyjs::show("preprocessing_execute_button")
  }
})

observeEvent(input$preprocessing_merge_museum_names, {
  if (length(input$preprocessing_merge_museum_names) > 1) {
    shinyjs::enable("preprocessing_select_merge_button")
  } else {
    shinyjs::disable("preprocessing_select_merge_button")
  }
})

observeEvent(input$preprocessing_merge_museum_text, {
  if (nchar(input$preprocessing_merge_museum_text) > 0) {
    shinyjs::enable("preprocessing_select_merge_button")
  } else {
    shinyjs::disable("preprocessing_select_merge_button")
  }
})

preprocess_active <- reactive({
  req_and_assign(input$preprocessing_select_museum, "id")
  req_and_assign(input$preprocessing_select_operation, "operation")
  
  tryCatch({
    fields <- get_fields(preprocess_operations[[operation]]$run)
    data <- preprocess_museums$data[[which(preprocess_museums$id == id)]]
    
    original <- save_museums$data[[which(save_museums$id == id)]]
    attr(original, "select") <- 1:nrow(original)
  }, error = function(e) {
    return(FALSE)
  })

  value <- TRUE
  
  if ("row" %in% names(fields)) {
    row <- input$preprocessing_preview_rows_all
    
    filter <- c(input$preprocessing_preview_search, 
      input$preprocessing_preview_search_columns)
    filter <- filter[filter != ""] 

    # special case
    if (operation == "yesfilter" & length(filter) == 0) {
      value <- FALSE
    }

    # special case
    if (operation %in% c("nofilter", "lastfilter") & 
        length(attr(data, "select")) == nrow(data)) {
      value <- FALSE
    }
  }
  
  if ("column" %in% names(fields)) {
    column <- input$preprocessing_select_column
    min_columns <- preprocess_operations[[operation]]$min_columns
    text_column <- FALSE
    
    # special case
    if (operation == "cdelete") {
      text <- input$preprocessing_operation_text
      min_columns <- 1

      if (!is.null(text)) {
        if (text <= 0) text_column <- TRUE
      }
    }
    
    if ((length(column) < min_columns) & text_column) {
      value <- FALSE
    }
  }
  
  if ("museum" %in% names(fields)) {
    museum <- input$preprocessing_select_museums
    min_museums <- preprocess_operations[[operation]]$min_museums

    if (length(museum) < min_museums) {
      value <- FALSE
    }
  }

  if ("edit" %in% names(fields)) {
    req_and_assign(preprocess_cell_edits, "edit")
    
    if (length(edit$data[id][[1]]) == 0) {
      value <- FALSE
    }
  }
  
  if ("text" %in% names(fields)) {
    text <- input$preprocessing_operation_text

    # partial special case
    if (!(operation %in% c("cpaste", "cdelete"))) {
      if (!is_empty(text)) {
        value <- FALSE
      }
    }
  } else if ("name" %in% names(fields)) {
    new_column_text <- input$preprocessing_new_column_text
    
    if (!is_empty(new_column_text)) {
      value <- FALSE
    }
  }

  # special case
  if (operation == "reverse") {
    if (all.equal(data, original)[1] == TRUE) {
      value <- FALSE
    }
  }
  
  # special case
  if (operation == "cpaste") {
    column_text <- input$preprocessing_new_column_text
    
    if (!is_empty(column_text)) {
      value <- FALSE
    }
  }

  return(value)
})

observeEvent(preprocess_active(), {
  if (preprocess_active()) {
    shinyjs::enable("preprocessing_execute_button")
  } else { 
    shinyjs::disable("preprocessing_execute_button")
    shinyjs::hide("preprocessing_all_museums_check")
  }
})

observe({
  # this has to be set for the observer to work correctly
  column <- input$preprocessing_select_column

  if (is_true(input$preprocessing_new_column_check)) {
    shinyjs::show("preprocessing_new_column_text")
  } else { 
    shinyjs::hide("preprocessing_new_column_text")
  }
}, priority = -1)

observeEvent(input$preprocessing_select_museum, {
  req_and_assign(input$preprocessing_select_museum, "id")

  if (id != "") {
    n_process <- length(preprocess_museums$id) + 1
    id_museum <- which(save_museums$id == id)
    
    if (!(id %in% preprocess_museums$id)) {
      preprocess_museums$id[n_process] <- save_museums$id[id_museum]
      preprocess_museums$names[n_process] <- save_museums$names[id_museum]
      preprocess_museums$data[[n_process]] <- save_museums$data[[id_museum]]
      
      attr(preprocess_museums$data[[n_process]], "select") <- 
        1:nrow(preprocess_museums$data[[n_process]])
    }
  }
})

observeEvent(input$preprocessing_execute_button, {
  progress <- shiny::Progress$new()
  on.exit(progress$close())
  progress$set(message = "Museum wird bearbeitet", value = 50)
  
  req_and_assign(input$preprocessing_select_museum, "id")
  req_and_assign(input$preprocessing_select_operation, "operation")
  
  data <- preprocess_museums$data[[which(preprocess_museums$id == id)]]
  index <- which(names(preprocess_history$data) == id)
  active <- preprocess_history$active[index]
  
  run <- preprocess_operations[[operation]]$run
  fields <- get_fields(run)
  
  if ("row" %in% names(fields)) {
    filter <- NULL
    multiple <- FALSE
    row <- NULL
    
    # special case
    if (operation == "yesfilter") {
      filter <- c(input$preprocessing_preview_search, 
        input$preprocessing_preview_search_columns)
      
      names(filter) <- c("Global", colnames(data))
      filter <- filter[filter != ""]
      
      multiple <- TRUE
      
      row <- input$preprocessing_preview_rows_all
      if (is.null(row)) row <- 1:nrow(data)
    }
    
    # special case
    if (operation == "lastfilter") {
      history <- preprocess_history$data[[id]]
      filters <- active_filters(history, active)
      result <- last_filter(filters)
          
      filter <- result$filter
      row <- result$row
    }
  }
  
  if ("column" %in% names(fields)) {
    column <- input$preprocessing_select_column
  }
  
  if ("museum" %in% names(fields)) {
    museum <- input$preprocessing_select_museums
  }
  
  if ("edit" %in% names(fields)) {
    edit <- preprocess_cell_edits$data[id][[1]]
    preprocess_cell_edits$data[id] <- NULL
  }
  
  if ("text" %in% names(fields)) {
    text <- input$preprocessing_operation_text
  }
  
  if ("name" %in% names(fields)) {
    name <- input$preprocessing_new_column_text
    
    if (!is.null(preprocess_operations[[operation]]$check)) {
      if (!input$preprocessing_new_column_check) name <- NULL
    }
  }
  
  if ("vertical" %in% names(fields)) {
    vertical <- input$preprocessing_vertical_check
  }

  fields_paste <- paste(names(fields)[-length(fields)], collapse = ", ")
  result <- eval(parse(text = paste0(run, "(", fields_paste, ")")))
  
  if (!("error" %in% result$error)) {
    history <- list(time = format(Sys.time(), "%H:%M"), operation = operation)
    last <- length(preprocess_history$data[[id]])
    
    for (i in seq(length(names(fields)))) {
      if (names(fields)[i] != "data") {
        try({
          history[names(fields)[i]] <- list(get(names(fields)[i]))
        }, silent = TRUE)
      }
    }

    if (length(index) > 0) {
      active <- as.integer(active)

      if (active < last) {
        delete <- (active + 1):last

        preprocess_history$data[id][[1]] <- 
          preprocess_history$data[id][[1]][-delete]
        last <- length(preprocess_history$data[[id]])
      }
    }
    
    preprocess_history$data[id][[1]][[last + 1]] <- history
    index <- which(names(preprocess_history$data) == id)
    preprocess_history$active[index] <- last + 1

    preprocess_museums$data[[which(preprocess_museums$id == id)]] <- result$data
    updateTextAreaInput(session, "preprocessing_operation_text", value = "")
  }
})

observeEvent(input$load_preprocessing_history_count, {
  cat("add history count\n")
  
  req_and_assign(input$preprocessing_select_museum, "id")
  history_id <- which(names(preprocess_history$data) == id)
  preprocess_id <- which(preprocess_museums$id == id)
  
  clicked <- input$load_preprocessing_history_button
  clicked <- gsub(".*history_", "", clicked)
  active <- preprocess_history$active[history_id]
  
  if (!is.null(active) & length(active) > 0) {
    if (active != clicked) {
      data <- preprocess_museums$data[[preprocess_id]]
      
      if (!is.null(data)) {
        progress <- shiny::Progress$new()
        on.exit(progress$close())
        progress$set(message = "Museum wird bearbeitet", value = 50)

        if (as.integer(clicked) < as.integer(active)) {
          data <- apply_reverse(data)$data
          active <- 0
        }

        if (as.integer(clicked) > 0) {
          history <- preprocess_history$data[[history_id]]
          filters <- active_filters(history, active)

          for (i in (as.integer(active) + 1):(as.integer(clicked))) {
            operation_name <- history[[i]]$operation
            operation <- preprocess_operations[[operation_name]]$run
            
            if (operation_name == "lastfilter") {
              result <- last_filter(filters)
              
              history[[i]]$filter <- result$filter
              history[[i]]$row <- result$row
            }
            
            if (operation_name == "yesfilter") {
              history[[i]]$multiple <- TRUE
            }
            
            filters <- active_filter(history[[i]], filters)

            arguments <- history[[i]][-c(1, 2)]
            arguments$data <- data
  
            data <- do.call(eval(parse(text = operation)), arguments)$data
            
            if (grepl("filter", operation_name)) {
              history[[i]]$row <- attr(data, "select")
              preprocess_history$data[history_id][[1]][[i]] <- history[[i]]
            }
          }
        }

        preprocess_history$active[history_id] <- clicked
        preprocess_museums$data[[preprocess_id]] <- data
      }
    }
  }
})

observeEvent(input$preprocessing_merge_button, {
  merge_modal()
  
  shinyjs::disable("preprocessing_select_merge_button")

  if (length(save_museums$id) == 0) {
    shinyjs::disable("preprocessing_merge_museum_names")
  }
})

observeEvent(input$preprocessing_history_button, {
  general_modal()
})

observeEvent(input$preprocessing_abort_history_button, {
  if (preprocess_selected_history$load) {
    general_modal()
  } else {
    removeModal()
  }
})

observeEvent(input$preprocessing_select_merge_button, {
  museum <- input$preprocessing_merge_museum_names
  text <- input$preprocessing_merge_museum_text
  
  apply_museum_merge(NULL, museum, text)
})

observe({
  req_and_assign(preprocess_history$data, "history_data")
  req_and_assign(input$preprocessing_select_museum, "id")
  
  history_data <- exclude_id_from_data(history_data, id)
  
  if (length(history_data) > 0) {
    shinyjs::enable("preprocessing_history_transfer")
  } else {
    shinyjs::disable("preprocessing_history_transfer")
  }
})

observeEvent(input$preprocessing_history_transfer, {
  id_museum <- input$preprocessing_select_museum
  
  data <- preprocess_history$data
  data <- exclude_id_from_data(data, id_museum)

  labels <- preprocess_museums$names
  names(labels) <- preprocess_museums$id
  
  ids <- names(data)
  names(ids) <- ids
  
  for (id in names(ids)) {
    ids[id] <- labels[id == names(labels)]
  }
  
  attr(data, "type") <- "history"
  attr(data, "labels") <- unname(ids)
  
  preprocess_selected_history$data <- data
  preprocess_selected_history$load <- FALSE
  
  special_modal(data)
})

observeEvent(input$preprocessing_select_history_button, {
  id_museum <- input$preprocessing_select_museum
  id_history <- input$preprocessing_select_history
  
  data <- preprocess_selected_history$data
  modify <- input$preprocessing_modify_history
  replace <- input$preprocessing_replace_history
  
  load_history(id_museum, id_history, data, modify, replace)
})

observeEvent(input$preprocessing_history_progress_bar, {
  req_and_assign(input$preprocessing_history_progress_bar, "progress_bar")

  if (progress_bar == "Maximum upload size exceeded") {
    show_modal(paste("Die ausgewählte Datei ist zu groß und kann",
      "nicht importiert werden. Die maximale Dateigröße beträgt", 
      max_file_size, "MB."))
  }
  
  if (progress_bar == "Upload complete") {
    result <- read_data(input$preprocessing_load_history_button)
    error <- TRUE

    if (!is.null(result$data)) {
      test <- attr(result$data, "type") == "history"

      if (length(test) > 0) {
        preprocess_selected_history$data <- result$data
        preprocess_selected_history$load <- TRUE
        
        error <- FALSE
      }
    }

    if (error) {
      show_modal(paste("Die ausgewählte Datei konnte nicht eingelesen",
        "werden. Es handelt sich nicht um eine Historie."), title = "Fehler")
    } else {
      special_modal(result$data)
    }
  }
})

output$preprocessing_save_history_button <- shiny::downloadHandler(
  filename = function() {
    name = paste("historie", Sys.Date(), sep = "_")
    paste0(name, ".rds")
  },
  
  content = function(file) {
    data <- preprocess_history$data
    labels <- preprocess_museums$names
    names(labels) <- preprocess_museums$id
    
    ids <- names(data)
    names(ids) <- ids
    
    for (id in names(ids)) {
      ids[id] <- labels[id == names(labels)]
    }

    attr(data, "type") <- "history"
    attr(data, "labels") <- unname(ids)
    
    saveRDS(data, file)
    removeModal()
  }
)

### Outputs ###################################################################

observeEvent(input$preprocessing_preview_cell_edit, {
  req_and_assign(input$preprocessing_select_museum, "id")
  cell_edit <- input$preprocessing_preview_cell_edit
  
  length <- length(preprocess_cell_edits$data[id][[1]])
  preprocess_cell_edits$data[id][[1]][[length + 1]] <- cell_edit
})

output$preprocessing_preview <- DT::renderDataTable({
  shiny::validate(
    need(input$preprocessing_select_museum != "", 
      paste("Bitte importieren Sie zunächst mindestens",
        "ein Museum im Reiter „Dashboard“")
    )
  )
  
  req_and_assign(input$preprocessing_select_museum, "id")
  data <- preprocess_museums$data[[which(preprocess_museums$id == id)]]

  shiny::validate(
    need(ncol(data) > 0, 
      paste("Das Museum weist keine Spalten auf")
    )
  )

  data[attr(data, "select"), , drop = FALSE]
}, escape = FALSE, rownames = FALSE, style = "bootstrap", filter = "top", 
  editable = TRUE, server = TRUE, options = list(pageLength = 15, info = TRUE, 
  pagingType = "numbers", lengthChange = TRUE, searchHighlight = TRUE, 
  search = list(smart = FALSE), rowCallback = JS(
    "function(row, data, index, indexfull) {",
    "for (var i = 0; i < data.length; i++) {",
    "$('td:eq(' + i + ')', row).attr('title', data[i]);}}"), 
  initComplete = JS(
    "function(settings, json) {",
    "$('#preprocessing_preview table').doubleScroll();}")
  )
)

output$preprocessing_select_operation <- renderUI({
  req_and_assign(input$preprocessing_select_operation, "operation")
  fields <- get_fields(preprocess_operations[[operation]]$run)
  
  tag_list <- tagList()
  
  if ("column" %in% names(fields)) {
    req_and_assign(input$preprocessing_select_museum, "id")
    id <- which(preprocess_museums$id == id)

    tag_list <- tagAppendChildren(tag_list, 
      selectInput("preprocessing_select_column", "Spalten auswählen",
        choices = colnames(preprocess_museums$data[[id]]), multiple = TRUE)
    )
  }
  
  if ("museum" %in% names(fields)) {
    museums <- save_museums$id
    names(museums) <- save_museums$names
    
    tag_list <- tagAppendChildren(tag_list, 
      selectInput("preprocessing_select_museums", "Museen auswählen",
        choices = museums, multiple = TRUE)
    )
  }
  
  return(tag_list)
})

output$preprocessing_specify_operation <- renderUI({
  req_and_assign(input$preprocessing_select_operation, "operation")
  
  column <- input$preprocessing_select_column
  museum <- input$preprocessing_select_museums
  
  run <- preprocess_operations[[operation]]$run
  fields <- get_fields(run)

  tag_list <- tagList()
  
  if ("column" %in% names(fields)) {
    if (length(column) < preprocess_operations[[operation]]$min_columns) {
      return(tag_list)
    }
  }
  
  if ("museum" %in% names(fields)) {
    if (length(museum) < preprocess_operations[[operation]]$min_museums) {
      return(tag_list)
    }
  }
  
  if ("text" %in% names(fields) | run == "button") {
    ui <- preprocess_operations[[operation]]$text
    text <- get(paste("preprocessing", operation, "text", sep = "_"))
    text$inputId <- "preprocessing_operation_text"
  
    tag_list <- tagAppendChildren(tag_list, 
      do.call(eval(parse(text = paste0(ui, "Input"))), text))
  }

  if (!is.null(preprocess_operations[[operation]]$check)) {
    if (length(column) == 1) name <- "Spalte" else name <- "Spalten"
    
    tag_list <- tagAppendChildren(tag_list, 
      checkboxInput("preprocessing_new_column_check", 
        sprintf("Neue %s anlegen", name), value = FALSE)
    )
  }
  
  if ("vertical" %in% names(fields)) {
    tag_list <- tagAppendChildren(tag_list, 
      checkboxInput("preprocessing_vertical_check", 
        "Spalten vertikal trennen", value = FALSE)
    )
  }
  
  if ("name" %in% names(fields)) {
    if (!is.null(preprocess_operations[[operation]]$single_name)) {
      if (length(column) >= preprocess_operations[[operation]]$min_columns) {
        tag_list <- tagAppendChildren(tag_list, 
          textInput("preprocessing_new_column_text", "Spaltenname")
        )
      }
    } else {
      if (length(column) == 1) {
        tag_list <- tagAppendChildren(tag_list, 
          textInput("preprocessing_new_column_text", "Spaltenname")
        )
      } else {
        tag_list <- tagAppendChildren(tag_list, 
          textAreaInput("preprocessing_new_column_text", "Spaltennamen", 
            placeholder = paste0("Bitte trennen Sie die Spaltennamen ",
              "durch einen Zeilenumbruch"))
        )
      }
    }
  }

  return(tag_list)
})

output$preprocessing_name_operation <- renderUI({
  tag_list <- tagList()
  
  if (length(save_museums$id) > 0) {
    choices <- list("Bitte wählen Sie eine Operation aus" = "")
    
    for (index in seq(length(preprocess_operations))) {
      name <- names(preprocess_operations)[index]
      category <- preprocess_operations[[index]]$category
      if (is.null(category)) category <- "misc"

      switch(category,
        "row"    = {
          choices$`Zeilenoperationen` <- 
            c(choices$`Zeilenoperationen`, get_operation_name(name))
        },
        "column" = {
          choices$`Spaltenoperationen` <- 
            c(choices$`Spaltenoperationen`, get_operation_name(name))
        },
        "cell" = {
          choices$`Zellenoperationen` <- 
            c(choices$`Zellenoperationen`, get_operation_name(name))
        },
        "museum" = {
          choices$`Museumsoperationen` <-
            c(choices$`Museumsoperationen`, get_operation_name(name))
        },
        "misc"   = {
          choices$`Sonstiges` <- 
            c(choices$`Sonstiges`, get_operation_name(name))
        }
      )
    }
    
    tag_list <- tagList(
      selectInput("preprocessing_select_operation",
        "Operation auswählen", choices = choices),
      videoButton("preprocessing_video", 
        text = "dieser Operation")
    )
  }

  return(tag_list)
})

output$preprocessing_history <- renderUI({
  req_and_assign(input$preprocessing_select_museum, "id")
  id <- which(names(preprocess_history$data) == id)
  data <- preprocess_history$data[input$preprocessing_select_museum][[1]]

  if (!is.null(data)) {
    data <- lapply(data, function(x) return({
      if (length(x$column) > 0) {
        x$column <- paste(x$column, collapse = ", ")
        x$column <- gsub("\\", "\\\\", x$column, fixed = TRUE)
      } else {
        x$column <- NA
      }
      
      if (length(x$museum) > 0) {
        x$museum <- paste(x$museum, collapse = ", ")
        x$museum <- gsub("\\", "\\\\", x$museum, fixed = TRUE)
      } else {
        x$museum <- NA
      }
      
      if (is.null(x$text)) {
        x$text <- NA
      } else {
        if (is.na(x$text)) x$text <- ""
        x$text <- as.character(x$text)
        
        x$text <- paste(strsplit(x$text, "\n")[[1]], collapse = ", ")
        x$text <- gsub("\\", "\\\\", x$text, fixed = TRUE)
        x$text <- gsub("\"", "'", x$text)
      }
      
      if (!is.null(x$filter)) {
        x$text <- paste0(x$filter, " (", names(x$filter), ")")
        x$text <- paste(x$text, collapse = ", ")
        x$text <- gsub("\"", "'", x$text)
      }
      
      if (is.null(x$name)) {
        x$name <- NA
      } else {
        x$name <- paste(strsplit(x$name, "\n")[[1]], collapse = ", ")
        x$name <- gsub("\\", "\\\\", x$name, fixed = TRUE)
        x$name <- gsub("\"", "'", x$name)
      }

      c(x$operation, x$time, 
        get(sprintf("preprocessing_%s_name", x$operation)),
        x$column, x$text, x$name, x$museum)
      })
    )
    
    data <- matrix(unlist(data), ncol = 7, byrow = TRUE)
    data <- rbind(c(NA, "", "Museum hinzufügen", rep(NA, 4)), data)
  } else {
    data <- matrix(c(NA, "", "Museum hinzufügen", rep(NA, 4)), ncol = 7)
  }
  
  data <- cbind(data, 0:(nrow(data) - 1))
  html_code <- "tags$ul(class = \"history\","
  
  for (i in rev(seq(nrow(data)))) {
    button <- preprocess_button_count
    hover <- ""
    
    if (!is.na(data[i, 4])) {
      if (grepl(", ", data[i, 4], fixed = TRUE)) {
        label <- "Spalten"
      } else {
        label <- "Spalte"
      }
      
      hover <- sprintf("%s%s: %s", hover, label, data[i, 4])
    }
    
    if (!is.na(data[i, 5])) {
      if (!(data[i, 1] %in% c("yesfilter", "lastfilter", "cdelete"))) {
        label <- get(sprintf("preprocessing_%s_text", data[i, 1]))$label
      } else {
        label <- "Filter"
        
        if (data[i, 1] == "cdelete") {
          label <- "Anteil leere Zellen"
        }
      }
      
      if (nchar(hover) != 0) hover <- paste0(hover, ", ")
      hover <- sprintf("%s%s: %s", hover, label, data[i, 5])
    }
    
    if (!is.na(data[i, 6])) {
      if (grepl(", ", data[i, 6], fixed = TRUE)) {
        label <- "Spaltennamen"
      } else {
        label <- "Spaltenname"
      }
      
      if (nchar(hover) != 0) hover <- paste0(hover, ", ")
      hover <- sprintf("%s%s: %s", hover, label, data[i, 6])
    }
    
    if (!is.na(data[i, 7])) {
      if (nchar(hover) != 0) hover <- paste0(hover, ", ")
      hover <- sprintf("%s%s: %s", hover, "Museen", data[i, 7])
    }
    
    active <- preprocess_history$active[id]
    class <- "class=\"active\""

    if (!is.null(active) & length(active) > 0) {
      if (active != data[i, 8]) {
        class <- "class=\"\""
      }
    }
    
    element <- sprintf(paste0("tags$li(id=\"preprocessing_history_%s\", %s, ",
        "`data-toggle`=\"tooltip\", title = \"%s\", ",
        "onclick = 'Shiny.onInputChange(\"load_preprocessing_history_button\",",
        " this.id); %s = %s + 1; Shiny.onInputChange(\"load_preprocessing_",
        "history_count\", %s)', tags$div(class = \"date\", \"%s\"),",
        "tags$div(class = \"title\", \"%s\")),"), 
      data[i, 8], class, hover, button, button, button, data[i, 2], data[i, 3])
    
    html_code <- paste0(html_code, element)
  }

  html_code <- substr(html_code, 1, nchar(html_code) - 1)
  html_code <- eval(parse(text = paste0(html_code, ")")))
  shinyjs::runjs("$('.tooltip').remove();")
  
  return(html_code)
})

output$preprocessing_export_button <- shiny::downloadHandler(
  filename = function() {
    name <- preprocess_museums$names[[which(preprocess_museums$id == id)]]
    
    name <- stringi::stri_replace_all_fixed(
      tolower(name), 
      c("ä", "ö", "ü", "ß", " "), 
      c("ae", "oe", "ue", "ss", "-"), 
      vectorize_all = FALSE
    )
    
    name <- paste(name, Sys.Date(), sep = "_")
    
    # append format given for export
    paste(name, tolower(input$preprocessing_operation_text), sep = ".")
  },
  
  content = function(file) {
    data <- preprocess_museums$data[[which(preprocess_museums$id == id)]]
    data <- data[attr(data, "select"), ]

    switch(tolower(input$preprocessing_operation_text),
      csv = write.table(data, file, row.names = FALSE, 
        sep = "\t", fileEncoding = "utf-8"),
      rds = saveRDS(data, file)
    )
  }
)