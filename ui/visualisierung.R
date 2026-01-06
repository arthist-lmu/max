panel_visualisierung <- tabItem(tabName = "visualize",
  fluidRow(
    column(width = 4,
      box(width = NULL, title = p("Museum visualisieren",
          tooltipButton("visualisierung_prepare_help"),
          videoButton("visualisierung_prepare_video")),
        selectInput("visualisierung_select_museum", "Museum auswählen",
          choices = c("Bitte importieren Sie zunächst ein Museum" = ""),
          multiple = TRUE),
               
        uiOutput("visualisierung_select_operation"),
        uiOutput("visualisierung_select_type"),

        actionButton("visualisierung_execute_button", "Diagramm zeichnen", 
          icon("play-circle"), width = "100%", class = "red")
      ),
      
      hidden(
        div(id = "visualisierung-settings",
          box(width = NULL, title = p("Einstellungen"), 
              collapsible = TRUE, collapsed = FALSE,
            textInput("visualisierung_name_title", 
              "Titel des Diagramms", value = ""),
            textInput("visualisierung_name_subtitle", 
              "Untertitel des Diagramms", value = ""),
            textInput("visualisierung_name_xaxis", 
              "Beschriftung der x-Achse", value = ""),
            textInput("visualisierung_name_yaxis", 
              "Beschriftung der y-Achse", value = ""),
            textInput("visualisierung_name_xlim",
              "Grenzwerte der x-Achse", value = ""),
            textInput("visualisierung_name_ylim",
              "Grenzwerte der y-Achse", value = "")
          )
        )
      )
    ),
    
    column(width = 8,                           
      box(width = NULL, title = p("Museum ansehen",
          tooltipButton("visualisierung_preview_help"),
          videoButton("visualisierung_preview_video")),
        highcharter::highchartOutput("visualisierung_preview", height = "600px")
      )
    )
  )
)