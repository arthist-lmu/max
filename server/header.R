bugreport_data <- reactive({
  # invalidateLater(300000) # update every five minutes
  
  try({
    # gs_key(key$google, lookup = FALSE, visibility = "private") %>% 
    #   gs_read() %>% filter(Status == "Offen") %>% nrow
  }, silent = TRUE)
})

observeEvent(bugreport_data(), {
  bugreport_data <- bugreport_data()
  # if (bugreport_data > 0 & !("try-error" %in% class(bugreport_data))) {
  #   updateActionButton(session, "header_bugreport_help", label = 
  #     doRenderTags(span(class = "label label-primary", bugreport_data)))
  # }
})

observeEvent(input$header_bugreport_help, {
  text <- div(id = "header-bugreport-modal",
    tags$p(paste("Fehler passieren. Damit sie aber nicht immer wieder",
      "passieren, können Sie uns Bugs melden, damit wir diese beheben.",
      "Bitte beschreiben Sie den jeweiligen Bug klar und präzise.")),
    selectInput("header_bugreport_where", 
      "In welchem Modul sind Sie dem Bug begegnet?",
      choices = c("Dashboard", "Preprocessing", 
                  "Visualisierung", "Sonstiges")),
    textAreaInput("header_bugreport_what", 
      paste("Wie äußert sich der Bug? Welche Schritte haben zu dem Bug",
        "geführt? Welche Ausgabe haben Sie eigentlich erwartet?"),
      resize = "vertical", rows = 5)
  )

  footer <- tagList(modalButton(icon("times")), actionButton(
    "bugreport_send_confirm", "Senden"), modalButton("Abbrechen"))
  
  showModal(div(class = "report", modalDialog(title = "Bugreport", 
    text, easyClose = TRUE, size = "s", footer = footer)
  ))
})

observeEvent(input$header_bugreport_what, {
  if (nchar(input$header_bugreport_what) > 0) {
    shinyjs::enable("bugreport_send_confirm")
  } else {
    shinyjs::disable("bugreport_send_confirm")
  }
})

observeEvent(input$bugreport_send_confirm, {
  tryCatch({
    removeModal(); Sys.sleep(0.5)
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Bugreport wird gesendet", value = 50)
    
    # send email with information about bugreport
    body <- paste0("Am ", format(Sys.time(), "%d.%m.%Y um %X"), " ist ein ",
      "neuer Bugreport in Google Spreadsheets eingegangen.")
    send_mail(subject = "MAX-Bugreport", body = body)
    
    # add row in googlesheets (general information)
    fields <- reactiveValuesToList(input)
    fields <- fields[!grepl(paste0("shinyjs|rows|state|clicked|search|",
      "confirm|help|bugreport|button"), names(fields))]
    fields <- fields[grepl("_", names(fields))]
    fields <- lapply(fields, function(x) ifelse(is.null(x), NA, x))
    fields <- data.frame(names = names(fields), values = 
      unlist(fields, use.names = FALSE))
    fields <- fields[order(fields$names), ]
    fields <- paste(fields$names, fields$values, sep = ": ", collapse = "\n")
    
    add_row <- gs_key(key$google, lookup = FALSE, visibility = "private") %>% 
      gs_add_row(input = c("Offen", format(Sys.time(), "%d.%m.%Y um %X"), 
        input$header_bugreport_where, input$header_bugreport_what, fields, ""))
    
    # add row in database (further information with history)
    connect <- dbConnect(MySQL(), user = key$phpmyadmin$user, 
      password = key$phpmyadmin$password, dbname = key$phpmyadmin$dbname,
      host = key$phpmyadmin$host, port = key$phpmyadmin$port)
    id <- dbGetQuery(connect, "SELECT id FROM bugreport_history")
    id <- ifelse(max(id$id) > 0, max(id$id) + 1, 1)
    dbWriteTable(connect, name = "bugreport_history", value = as.data.frame(
      list(id = id, date = format(Sys.time(), "%d.%m.%Y um %X"), 
        history = paste0(capture.output(dput(preprocess_history$data, "")),
        collapse = ""))), overwrite = FALSE, append = TRUE, row.names = 0)
    dbDisconnect(connect)

    show_modal(paste0("Der aufgegebene Bugreport wurde erfolgreich gesendet. ",
      "Vielen Dank für Ihre Mitteilung."), title = "Bugreport")
  }, error = function(e) {
    show_modal(paste0("Der aufgegebene Bugreport konnte nicht gesendet ",
      "werden. Es trat folgender Fehler auf:"), error = e)
  })
})