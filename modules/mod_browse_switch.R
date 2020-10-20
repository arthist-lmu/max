# module user interface
browse_switch_ui <- function(id) {
  ns <- NS(id)

  show_modal(
    selectInput(
      ns("language"), "Select language", choices = c(
        "English" = "en", "German" = "de", "French" = "fr"
      )
    ),
    actionButton(ns("button"), "Switch language"),
    title = "Information", `data-id` = gsub("-$", "", ns("")),
    size = "s" # note: reference by `data-id` in javascript
  )
}

# module server logic
browse_switch <- function(input, output, session) {
  ns <- session$ns

  observeEvent(input$button, {
    removeModal() # remove modal on button click
  })

  list(
    get_data = function() {
      req(input$button, isolate(input$language))

      return(input$language)
    }
  )
}
