panel_preprocessing <- tabItem(tabName = "preprocessing",
  fluidRow(
    column(width = 4,
      box(width = NULL, title = p("Museum bearbeiten",
          tooltipButton("preprocessing_cleanse_help"),
          tooltipButton("preprocessing_merge_button", 
            fa_icon = icon("compress"))),
        selectInput("preprocessing_select_museum", "Museum auswählen",
          choices = c("Bitte importieren Sie zunächst ein Museum" = "")),
        
        uiOutput("preprocessing_name_operation"),
        uiOutput("preprocessing_select_operation"),
        uiOutput("preprocessing_specify_operation"),
        
        checkboxInput("preprocessing_all_museums_check", 
          "Operation auf alle hinzugefügten Museen anwenden", value = FALSE),
        
        actionButton("preprocessing_execute_button", "Operation ausführen", 
          icon("play-circle"), width = "100%", class = "red"),
        
        downloadButton("preprocessing_export_button", "Operation ausführen", 
          width = "100%", style = "display: block", class = "red")
      ),
      
      hidden(
        div(id = "preprocessing-history",
          box(width = NULL, title = p("Historie", 
            videoButton("preprocessing_history_video"),
            tooltipButton("preprocessing_history_transfer", 
              fa_icon = icon("share")),
            tooltipButton("preprocessing_history_button", 
              fa_icon = icon("folder-o"))),
            collapsible = TRUE, collapsed = TRUE,
            uiOutput("preprocessing_history"))
        )
      )
    ),
         
    column(width = 8,                           
      box(width = NULL, title = p("Museum ansehen",
          tooltipButton("preprocessing_preview_help")),
        DT::dataTableOutput("preprocessing_preview")
      )
    )
  )
)