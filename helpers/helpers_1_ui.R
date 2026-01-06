loading_screen <- tags$div(class = "shiny-notification",
  tags$div(class = "shiny-notification-close"),
  tags$div(class = "shiny-notification-content",
    tags$div(class = "shiny-notification-content-text",
      tags$div(class = "shiny-progress-notification",
        tags$div(class = "progress progress-striped active",
          tags$div(class = "progress-bar")
        ),
        
        tags$div(class = "progress-text",
          tags$span(class = "progress-message", "Tool wird geladen"),
          tags$span(class = "progress-detail")
        )
      )
    )
  )
)

show_modal <- function(text, title = "Fehler", error = NULL, 
    confirm = FALSE, button_name = NULL) {
  if (!is.null(error)) {
    error <- gsub("<|>|simple", "", error)
    error <- gsub("br /", "<br />", error)
    error <- paste(error, collapse = "\n")
    
    text <- paste0(text, "<div class = 'error'><code>", 
      error, "</code></div>")
  }
  
  if (confirm) {
    footer <- tagList(modalButton(icon("times")), 
      actionButton(button_name, "Ja"), modalButton("Nein"))
    modal_class <- "confirm"
  } else {
    footer <- modalButton(icon("times"))
    modal_class <- "error"
  }
  
  if (nchar(text) > 175) {
    modal_class <- paste0(modal_class, " wider")
  }
  
  showModal(div(class = modal_class, modalDialog(title = title, 
    HTML(text), easyClose = TRUE, size = "s", footer = footer)
  ))
}

show_video <- function(url, title = "Screencast") {
  text <- paste('<iframe allow="autoplay; encrypted-media" allowfullscreen=""',
    'style="position: absolute; width: 100%; height: 100%; top: 0; left: 0;',
    'border: 0;" src="', url, '"frameborder="0"></iframe>')
  footer <- modalButton(icon("times"))
  
  showModal(div(class = "video", modalDialog(title = title, 
    HTML(text), easyClose = TRUE, size = "l", footer = footer)
  ))
}

add_input <- function(FUN, ids, id, class = NULL, ...) {
  inputs <- NULL
  
  for (i in ids) {
    inputs <- c(inputs, as.character(FUN(paste0(id, i), ...)))
  }
  
  if (!is.null(class)) {
    inputs <- gsub("btn ", paste0("btn ", class, " "), inputs)
  }
  
  return(inputs)
}

tooltipButton <- function(id, label = "", fa_icon = icon("info-circle"), ...) {
  button <- actionButton(id, label, icon = fa_icon, title = get(id), 
    'data-toggle' = "tooltip", 'data-placement' = "auto top", ...)

  return(button)
}

videoButton <- function(id, label = "", fa_icon = icon("question-circle"), 
    text = "diesem Teilbereich", ...) {
  text <- paste("Sehen Sie sich einen Screencast zu", text, "an")
  button <- actionButton(id, label, icon = fa_icon, title = text, 
    'data-toggle' = "tooltip", 'data-placement' = "auto top", ...)

  return(button)
}

options(DT.options = list(lengthChange = FALSE, 
  pagingType = "simple", info = FALSE, 
  dom = "<\"top\">rt<\"bottom\"iflp><\"clear\">", 
  search = list(regex = TRUE), 
  language = list(search = "", searchPlaceholder = "Filter", 
    emptyTable = "Keine Daten in der Tabelle vorhanden", 
    info = "_START_ bis _END_ von _TOTAL_ Einträgen", 
    infoEmpty = "0 bis 0 von 0 Einträgen", 
    infoFiltered = "(gefiltert von _MAX_ Einträgen)", 
    infoThousands = ".", 
    lengthMenu = "_MENU_ Einträge anzeigen", 
    loadingRecords = "Wird geladen ...", 
    processing = "Bitte warten ...", 
    zeroRecords = "Keine Einträge vorhanden.", 
    paginate = list(`first` = "<i class='fa fa-angle-left'></i>", 
      `previous` = "<i class='fa fa-angle-left'></i>", 
      `next` = "<i class='fa fa-angle-right'></i>", 
      `last` = "<i class='fa fa-angle-right'></i>"), 
    aria = list(sortAscending = ": Spalte aufsteigend sortieren",
      sortDescending = ": Spalte absteigend sortieren"))))

pdf(NULL) # fix problem in plot printout

hc_theme_font <- "Roboto"

hc_theme_max <- hc_theme(
  chart = list(
    backgroundColor = "#ffffff",
    fontFamily = hc_theme_font,
    plotBorderWidth = "0",
    plotBorderColor = "transparent",
    spacingBottom = 0,
    spacingTop = 10,
    spacingLeft = 0,
    spacingRight = 0,
    style = list(
      overflow = "visible"
    )
  ),
  title = list(
    style = list(
      color = "#333333",
      fontFamily = hc_theme_font,
      fontSize = "16px",
      fontWeight = "bold"
    )
  ),
  subtitle = list(
    style = list(
      color = "#333333",
      fontFamily = hc_theme_font,
      fontSize = "13px",
      fontWeight = "normal"
    )
  ),
  legend = list(
    align = "center",
    lineHeight = "20px",
    itemMarginBottom = 5,
    itemStyle = list(
      color = "#333333",
      fontFamily = hc_theme_font,
      fontSize = "13px",
      fontWeight = "normal"
    ) 
  ),
  tooltip = list(
    backgroundColor = "transparent",
    borderColor = "transparent",
    
    style = list(
      color = "#ffffff",
      padding = "0px"
    )
  )
)

hcoptslang <- getOption("highcharter.lang")
hcoptslang$thousandsSep <- "."
hcoptslang$decimalPoint <- ","
hcoptslang$downloadPNG <- "Als PNG-Datei exportieren"
hcoptslang$downloadJPEG <- "Als JPEG-Datei exportieren"
hcoptslang$resetZoom <- "Zurücksetzen"
hcoptslang$resetZoomTitle <- "Zurücksetzen"
hcoptslang$noData <- "Keine Daten"
hcoptslang$contextButtonTitle <- "Exportieren"
options(highcharter.lang = hcoptslang)
