### General ###################################################################

visualize_museums <- reactiveValues(data = NULL, class = NULL, count = 0)
colors <- list(small = c("#332288", "#6699CC", "#88CCEE", "#44AA99", "#117733", 
                         "#999933", "#DDCC77", "#661100", "#CC6677", "#AA4466", 
                         "#882255", "#AA4499"), 
               large = c("#0000FF", "#FF0000", "#00FF00", "#000033", "#FF00B6", 
                         "#005300", "#FFD300", "#009FFF", "#9A4D42", "#00FFBE", 
                         "#783FC1", "#1F9698", "#FFACFD", "#B1CC71", "#F1085C", 
                         "#FE8F42", "#DD00FF", "#201A01", "#720055", "#766C95", 
                         "#02AD24", "#C8FF00", "#886C00", "#FFB79F", "#858567", 
                         "#A10300", "#14F9FF", "#00479E", "#DC5E93", "#93D4FF", 
                         "#004CFF", "#F2F318"))

colors$small <- hex_to_rgba(colors$small)
colors$large <- hex_to_rgba(colors$large)

shinyjs::hide("visualisierung-settings")
updateSelectInput(session, "visualisierung_select_operation", select = "")

### Videos ####################################################################

observeEvent(input$visualisierung_prepare_video, {
  show_video(get("visualisierung_prepare_video_url"))
})

observeEvent(input$visualisierung_preview_video, {
  show_video(get("visualisierung_preview_video_url"))
})

### Functions #################################################################

get_boxplot_info <- function() {
  paste0(" + '<br>Maximum: ' + this.point.high",
         " + '<br>Oberes Quartil: ' + this.point.q3",
         " + '<br>Median: ' + this.point.median",
         " + '<br>Unteres Quartil: ' + this.point.q1",
         " + '<br>Minimum: ' + this.point.low")
}

get_limit <- function(limit) {
  limit <- strsplit(limit, " ")[[1]]
  limit <- as.numeric(limit)
  
  if (length(limit) == 1) limit[2] <- 0
  if (limit[1] > limit[2]) limit <- limit[c(2, 1)]
  
  return(limit)
}

get_valid_columns <- function(ids, original, preprocessed) {
  columns <- NULL
  
  for (id in ids) {
    if (id %in% preprocessed$id) {
      id <- which(preprocessed$id == id)
      columns <- c(columns, colnames(preprocessed$data[[id]]))
    } else {
      id <- which(original$id == id)
      columns <- c(columns, colnames(original$data[[id]]))
    }
  }
  
  return(columns)
}

get_valid_data <- function(ids, columns, original, preprocessed) {
  data_museums <- list()
  data_classes <- list()
  
  for (id in ids) {
    if (id %in% preprocessed$id) {
      id <- which(preprocessed$id == id)
      name <- preprocessed$names[id]
      data_museum <- preprocessed$data[[id]]
      select <- attr(data_museum, "select")
    } else {
      id <- which(original$id == id)
      name <- original$names[id]
      data_museum <- original$data[[id]]
      select <- 1:nrow(data_museum)
    }
    
    column <- sapply(columns, function(x) {
      which(colnames(data_museum) == x)})
    data_museum <- data_museum[select, column, drop = FALSE]
    data_museum$max_museum_name <- name
    
    data_museums[[length(data_museums) + 1]] <- data_museum
    data_classes[[length(data_classes) + 1]] <- sapply(data_museum, class)
  }
  
  data_classes <- do.call(rbind.data.frame, data_classes)

  for (i in 1:length(columns)) {
    if (length(unique(data_classes[[i]])) != 1) {
      for (j in 1:length(data_museums)) {
        data_museums[[j]][[i]] <- as.character(data_museums[[j]][[i]])
      }
    }
  }
  
  data_museums <- bind_rows(data_museums)
  
  return(data_museums)
}

apply_columns <- function(data, relative, type, xaxis, yaxis, binwidth) {
  message <- customTryCatch({
    museums <- unique(data$max_museum_name)
    
    data_class <- sapply(data, class)
    data_class[data_class == "integer"] <- "numeric"
    
    museum_colors <- ifelse(ncol(data) > 12, colors$large, colors$small)
    
    tooltip <- ifelse(relative, " %", "")
    graph <- highchart()

    if (length(museums) == 1) graph <- graph %>% hc_legend(enabled = FALSE)

    if (data_class[1] == "numeric") {
      breaks <- seq(
        floor(min(data[[1]], na.rm = TRUE) / binwidth) * binwidth, 
        floor(max(data[[1]], na.rm = TRUE) / binwidth) * binwidth + binwidth, 
        binwidth)
      
      graph <- add_axis(graph, breaks, relative, xaxis, yaxis, type, 0.25, 0.01)

      for (museum in unique(data[[2]])) {
        hist <- get_histogram(data[[1]][data[[2]] %in% c(museum)], breaks)
        graph <- add_series(graph, hist, museum, relative, museum_colors)
        museum_colors <- museum_colors[-1]
      }
    }
    
    if (data_class[1] %in% c("character", "factor")) {
      data <- data.frame(table(data[[1]], data[[2]]))
      graph <- add_axis(graph, unique(data[[1]]), relative, xaxis, yaxis, type)

      for (museum in unique(data[[2]])) {
        hist <- data[[3]][data[[2]] == museum]
        graph <- add_series(graph, hist, museum, relative, museum_colors)
        museum_colors <- museum_colors[-1]
      }
    }
    
    graph <- graph %>% 
      hc_tooltip(useHTML = TRUE, backgroundColor = NULL, shadow = FALSE, 
        formatter = JS(paste0("function(){return('<div style=\"background-color:' 
          + this.series.color + '\" class=\"tooltip-hc\">' + this.series.name +
          '<br>' + this.x + ': ' + + this.y + '", tooltip, "</div>')}")))
  })

  if ("error" %in% class(message$error)) {
    show_modal(paste0("Die ausgewählten Museen konnten nicht visualisiert werden. ",
      "Es trat folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal(paste0("Beim Visualisieren der Museen trat folgende Warnung ",
      "auf:"), title = "Warnung", error = capture.output(message$warning))
  }

  return(list(data = graph, error = class(message$error)))
}

apply_scatter <- function(data, xaxis, yaxis, type = "scatter") {
  message <- customTryCatch({
    data_class <- sapply(data, class)
    data_class[data_class == "integer"] <- "numeric"
    data_class <- data_class[-length(data_class)]
    
    if (ncol(data) > 12) {
      museum_colors <- colors$large
    } else {
      museum_colors <- colors$small
    }
    
    labels <- c("", paste0(" + '", colnames(data)[1], ": ' + this.x"),
                paste0(" + '<br>", colnames(data)[2], ": ' + this.y"), "")

    graph <- highchart() %>% 
      hc_xAxis(title = list(text = xaxis)) %>% 
      hc_yAxis(title = list(text = yaxis))
    subgraph <- graph
    
    names_data <- colnames(data)
    data <- data[!is.na(data[[1]]) & !is.na(data[[2]]) & !is.na(data[[3]]), ]
    colnames(data)[1:2] <- c("x", "y")
    data$color <- museum_colors[1]
    
    if (length(data_class) == 3) {
      if (data_class[3] == "numeric") {
        labels[4] <- paste0(" + '<br>", colnames(data)[3], 
          ": ' + this.point.options.z")
        
        colnames(data)[3] <- "z"
        type <- "bubble"
      }
    }
    
    parsed_data <- rlist::list.parse(data)
    names(parsed_data) <- NULL

    if (data_class[1] == "numeric" & data_class[2] == "numeric") {
      subgraph <- add_series(graph, parsed_data, data$max_museum_name[1], 
        FALSE, museum_colors[1], type = type, legend = FALSE) 

      if (length(data_class) == 3) {
        if (data_class[3] %in% c("character", "factor")) {
          data$color <- as.numeric(as.factor(data[[3]]))
          data$color <- sapply(data$color, function(x) {museum_colors[x]})
          colnames(data)[3] <- "text"
          
          subgraph <- graph
          labels[1] <- "+ this.point.options.text + '<br>'"
          
          for (category in unique(data[[3]])) {
            data_category <- data[data[[3]] == category, ]
            parsed_data <- rlist::list.parse(data_category)
            names(parsed_data) <- NULL

            subgraph <- add_series(subgraph, parsed_data, category, 
              FALSE, unique(data_category$color)[1], type = "scatter") 
          }
        }
      }
    }
    
    if (data_class[1] == "numeric" & data_class[2] %in% c("character", "factor")) {
      subgraph <- suppressWarnings(
        hc_add_series_boxplot(graph, data[[1]], data[[2]], outliers = FALSE, 
          color = museum_colors[1], showInLegend = FALSE) %>% 
          hc_xAxis(title = list(text = yaxis)) %>% 
          hc_yAxis(title = list(text = xaxis)) %>%
          hc_chart(inverted = TRUE)
        )
      
      labels[2] <- paste0(" + '", names_data[2], ": ' + this.x")
      labels[3:4] <- c("", get_boxplot_info())
    }

    if (data_class[1] %in% c("character", "factor") & data_class[2] == "numeric") {
      subgraph <- suppressWarnings(
        hc_add_series_boxplot(graph, data[[2]], data[[1]], outliers = FALSE, 
          color = museum_colors[1], showInLegend = FALSE)
      )
      
      labels[3:4] <- c("", get_boxplot_info())
    }
    
    if (data_class[1] %in% c("character", "factor") & 
        data_class[2] %in% c("character", "factor")) {
      labels[3] <- paste0(" + '<br>' + this.series.name + ': ' + this.y + ' %'")
      
      table <- data.frame(table(data[[1]], data[[2]]))
      data <- merge(table, count(data, data[[1]]), by = 1)
      data$perc <- round(data$Freq / data$n * 100, 2)
      subgraph <- add_axis(graph, unique(data[[1]]), FALSE, xaxis, yaxis, "normal")
      
      for (category in unique(data[[2]])) {
        hist <- data[data[[2]] == category, 5]
        subgraph <- add_series(subgraph, hist, category, FALSE, museum_colors)
        museum_colors <- museum_colors[-1]
      }

      subgraph <- subgraph %>% 
        hc_yAxis(title = list(text = yaxis), max = 100,
          labels = list(format = "{value} %"))
    }
    
    graph <- subgraph %>% 
      hc_tooltip(useHTML = TRUE, backgroundColor = NULL, shadow = FALSE, 
        formatter = JS(paste0("function(){return('<div style=\"background-",
         "color:' + this.color + '\" class=\"tooltip-hc\">' ", labels[1], 
         labels[2], labels[3], labels[4], " + '</div>')}")))
  })

  if ("error" %in% class(message$error)) {
    show_modal(paste0("Die ausgewählten Museen konnten nicht visualisiert werden. ",
      "Es trat folgender Fehler auf:"), error = capture.output(message$error))
  } else if ("warning" %in% class(message$warning)) {
    show_modal("Beim Visualisieren der Museen trat folgende Warnung auf:",
      title = "Warnung", error = capture.output(message$warning))
  }
  
  return(list(data = graph, error = class(message$error)))
}

add_axis <- function(graph, data, relative, xaxis, yaxis, 
    type = "normal", border = 0, group = 0.2) {
  graph <- graph %>% 
    hc_xAxis(categories = data, title = list(text = xaxis))
  if (is.null(type)) type <- "normal"
    
  if (type == "normal") {
    graph <- graph %>% hc_plotOptions(column = list(stacking = type, 
      pointPadding = 0, borderWidth = border, groupPadding = group))
  } else {
    graph <- graph %>% hc_plotOptions(column = list(pointPadding = 0,
      borderWidth = border, groupPadding = group))
  }
  
  if (relative) {
    graph <- graph %>%
      hc_yAxis(title = list(text = yaxis),
        labels = list(format = "{value} %"))
    
    if (type == "grouped") 
      graph <- graph %>% hc_yAxis(max = 100)
  } else {
    graph <- graph %>%
      hc_yAxis(title = list(text = yaxis))
  }
  
  return(graph)
}

add_series <- function(graph, data, name, relative, 
    color, type = "column", legend = TRUE) {
  if (relative) data <- round(data / sum(data) * 100, 2)
  
  graph <- graph %>% hc_add_series(data = data, name = name, 
    type = type, color = color[1], marker = list(symbol = "circle"),
    showInLegend = legend)
  
  return(graph)
}

### User Interface Elements ###################################################

observe({
  museums <- save_museums$id
  names(museums) <- save_museums$names
  
  if (length(museums) > 0) {
    shinyjs::enable("visualisierung_select_museum")
    updateSelectInput(session, "visualisierung_select_museum", 
      choices = museums)
  } else {
    updateSelectInput(session, "visualisierung_select_museum", 
      choices = c("Bitte importieren Sie zunächst ein Museum" = ""))
    shinyjs::disable("visualisierung_select_museum")
  }
})

observe({
  shinyjs::disable("visualisierung_execute_button")
  
  req_and_assign(input$visualisierung_select_museum, "ids")
  req_and_assign(input$visualisierung_select_column, "columns")

  if ((length(ids) > 0 & length(columns) == 1) |
      (length(ids) == 1 & length(columns) < 4)) {
    shinyjs::enable("visualisierung_execute_button")
  }
})

output$visualisierung_select_operation <- renderUI({
  req_and_assign(input$visualisierung_select_museum, "ids")
  
  tag_list <- tagList()
  
  if (length(ids) > 0) {
    columns <- get_valid_columns(ids, save_museums, preprocess_museums)
    
    if (length(columns) > 0) {
      columns <- data.frame(table(columns), stringsAsFactors = FALSE)
      columns <- columns[columns$Freq == length(ids), ]

      if (nrow(columns) > 0) {
        columns <- as.character(columns$columns)
        tag_list <- tagList(selectInput("visualisierung_select_column", 
          "Spalten auswählen", choices = columns, multiple = TRUE))
      }
    }
  }

  return(tag_list)
})

output$visualisierung_select_type <- renderUI({
  req_and_assign(input$visualisierung_select_museum, "ids")
  req_and_assign(input$visualisierung_select_column, "columns")
  
  data <- get_valid_data(ids, columns, save_museums, preprocess_museums)
  
  data_class <- sapply(data, class)
  data_class[data_class == "integer"] <- "numeric"
  
  tag_list <- tagList()
  
  if (length(ids) > 1 & length(columns) == 1) {
    tag_list <- tagList(
      selectInput("visualisierung_type_name", "Diagrammtyp", 
        choices = c("Gestapeltes Diagramm" = "normal", 
          "Gruppiertes Diagramm" = "grouped")))
  }
  
  if (length(columns) == 1 & data_class[1] == "numeric") {
    tag_list <- tagAppendChildren(tag_list,
      sliderInput("visualisierung_hist_binwidth",
        "Breite der Klassen", min = 1, max = 100, value = 10))
  }
  
  if (length(ids) > 0 & length(columns) == 1) {
    tag_list <- tagAppendChildren(tag_list,
      checkboxInput("visualisierung_select_relative",
        "Relative Häufigkeiten antragen", FALSE))
  }

  return(tag_list)
})

observeEvent(input$visualisierung_execute_button, {
  req_and_assign(input$visualisierung_select_museum, "ids")
  req_and_assign(input$visualisierung_select_column, "columns")
  
  progress <- shiny::Progress$new()
  on.exit(progress$close())
  progress$set(message = "Museum wird visualisiert", value = 50)
  
  xaxis <- input$visualisierung_name_xaxis
  yaxis <- input$visualisierung_name_yaxis
  binwidth <- input$visualisierung_hist_binwidth

  data <- get_valid_data(ids, columns, save_museums, preprocess_museums)

  if (length(columns) == 1) {
    relative <- input$visualisierung_select_relative
    type <- input$visualisierung_type_name
    
    result <- apply_columns(data, relative, type, xaxis, yaxis, binwidth)
  } else {
    result <- apply_scatter(data, xaxis, yaxis)
  }

  if (!("error" %in% result$error)) {
    shinyjs::show("visualisierung-settings")

    visualize_museums$data <- result$data
    visualize_museums$class <- sapply(data, class)
    visualize_museums$count <- visualize_museums$count + 1
    
    relative <- input$visualisierung_select_relative
    labels <- columns

    if (length(columns) == 1) {
      labels[2] <- "Absolute Häufigkeit"
      
      if (is_true(relative)) 
        labels[2] <- "Relative Häufigkeit"
    }
    
    if (length(ids) > 0 & length(columns) > 0) {
      updateTextInput(session, "visualisierung_name_xaxis", value = labels[1])
      updateTextInput(session, "visualisierung_name_yaxis", value = labels[2])
      
      updateTextInput(session, "visualisierung_name_xlim", value = "")
      updateTextInput(session, "visualisierung_name_ylim", value = "")

      if (visualize_museums$class[1] == "numeric" & length(columns) > 1) {
        shinyjs::show("visualisierung_name_xlim")
      } else {
        shinyjs::hide("visualisierung_name_xlim")
      }

      if (visualize_museums$class[2] == "numeric" | length(columns) == 1) {
        shinyjs::show("visualisierung_name_ylim")
      } else {
        shinyjs::hide("visualisierung_name_ylim")
      }
    }
  } else {
    shinyjs::hide("visualisierung-settings")
  }
})

### Outputs ###################################################################

output$visualisierung_preview <- renderHighchart({
  shiny::validate(
    need(visualize_museums$count > 0,
      "Bitte wählen Sie mindestens ein Museum und mindestens eine Spalte aus"
    )
  )
  
  xlim <- input$visualisierung_name_xlim
  ylim <- input$visualisierung_name_ylim
  xaxis <- input$visualisierung_name_xaxis
  yaxis <- input$visualisierung_name_yaxis
  
  title <- input$visualisierung_name_title
  subtitle <- input$visualisierung_name_subtitle
  data_class <- visualize_museums$class

  graph <- isolate(visualize_museums$data) %>% hc_chart(zoomType = "xy",
      resetZoomButton = list(position = list(y = -5, x = -30),
        theme = list(fill = "transparent", stroke = "transparent", 
          states = list(hover = list(fill = "transparent"))))) %>%
    hc_yAxis(lineWidth = 0, minorGridLineWidth = 0) %>%
    hc_xAxis(lineWidth = 0, gridLineWidth = 0, tickLength = 0,
      minorGridLineWidth = 0) %>% hc_add_theme(hc_theme_max) %>%
    hc_exporting(enabled = TRUE, filename = paste0("max_plot_", Sys.Date()),
      buttons = list(contextButton = list(fill = "transparent"))) %>%
    hc_title(text = title, margin = 20, align = "center") %>%
    hc_subtitle(text = subtitle, margin = 20, align = "center")
  
  if (!is_empty(xlim)) {
    if (length(data_class) == 3 & data_class[1] == "numeric" & 
        data_class[2] %in% c("character", "factor")) {
      ylim <- xlim
      xlim <- ""
      
      xaxis <- c(xaxis, yaxis)
      yaxis <- xaxis[1]
      xaxis <- xaxis[2]
    }
  }  
  
  if (is_empty(xlim)) {
    xlim <- get_limit(xlim)
    graph <- graph %>% hc_xAxis(max = xlim[2])
    
    if (xlim[1] != 0) {
      graph <- graph %>% hc_xAxis(min = xlim[1])
    }
  }
  
  if (is_empty(ylim)) {
    ylim <- get_limit(ylim)
    graph <- graph %>% hc_yAxis(max = ylim[2])
    
    if (ylim[1] != 0) {
      graph <- graph %>% hc_yAxis(min = ylim[1])
    }
  }
  
  graph %>% hc_xAxis(title = list(text = xaxis)) %>% 
    hc_yAxis(title = list(text = yaxis))
})
