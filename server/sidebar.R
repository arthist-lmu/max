output$sidebar_objects <- renderUI({
  tagList(
    tags$div(class = "sidebar-labels",
      tags$span(class = "name", "Hinzugefügte Museen"),
      tags$span(class = "count", length(save_museums$id))
    ),
    
    sidebar_museums(save_museums$names)

    # tags$div(class = "sidebar-inventory",
    #   tags$div(class = "sidebar-count", style = 
    #     paste0("width: ", length(save_museums$id) * 10, "%;"))
    # )
  )
})


sidebar_museums <- function(names) {
  if (length(names) == 0) return(NULL)
  html_code <- "tags$ul(class = 'sidebar-museums',"
  
  for (i in seq_along(names)) {
    html_code <- paste0(html_code, "tags$li(\"", names[i], "\"),")
  }
  
  html_code <- substr(html_code, 1, nchar(html_code) - 1)
  return(eval(parse(text = paste0(html_code, ")"))))
}