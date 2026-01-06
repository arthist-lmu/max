panel_dashboard <- tabItem(tabName = "dashboard",
  fluidRow(
    box(width = 12, title = p(
        "Ein Online-Tool zur vergleichenden Analyse musealer Datenbestände", 
        tooltipButton("dashboard_example_help")),
      highcharter::highchartOutput("dashboard_example", height = "300px"))
  ),
  
  fluidRow(
    box(width = 6, title = p("Museum laden",
        tooltipButton("dashboard_load_help"),
        videoButton("dashboard_load_video")), 
      DT::dataTableOutput("dashboard_load")
    ),
    
    box(width = 6, title = p("Museum importieren",
        tooltipButton("dashboard_import_help"),
        videoButton("dashboard_import_video")),
      fluidRow(class = "row-changed-margin",
        fluidRow(
          column(width = 4,
            textInput("dashboard_import_name", 
              "Name des Museums", value = "")
          ),
          
          column(width = 4,
            div(id = "dashboard-import-file",
              fileInput("dashboard_import_file", "Datei auswählen",
                accept = c(".txt", ".csv", ".rds"),
                placeholder = "Keine Datei ausgewählt",
                buttonLabel = icon("file-text-o")
              )
            )
          ),
          
          column(width = 4, 
            tags$label(class = "hidden-text", "Datei importieren"),
            
            actionButton("dashboard_import_button", "Importieren", 
              icon("upload"), width = "100%", class = "red")
          )
        )
      ),
      
      hidden(div(id = "dashboard-import-input",
        fluidRow(class = "row-changed-margin",
          fluidRow(
            column(width = 4,
              selectInput("dashboard_import_file_header", 
                "Spaltennamen", selected = TRUE,
                choices = c("Ja" = TRUE, "Nein" = FALSE)
              )
            ),
            
            column(width = 4,
              textInput("dashboard_import_file_sep", "Trennzeichen", 
                placeholder = "Automatisch erkennen")
            ),
            
            column(width = 4,
              textInput("dashboard_import_file_quote", "Anführungszeichen",
                placeholder = "Automatisch erkennen")
            )
          )
        )
      )),
        
      fluidRow(
        hidden(div(id = "dashboard-import-table",
          tags$h3(class = "box-title", "Importierte Museen"),
          DT::dataTableOutput("dashboard_import"))
        )
      )
    )
  )
)
