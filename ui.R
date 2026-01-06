require(shiny)
require(shinydashboard)
require(RColorBrewer)
require(shinyjs)
require(highcharter)
require(DT)

helper_files <- list.files(path = "./helpers", pattern = "*.R")
helper_files <- paste0("helpers/", helper_files)

for (i in seq_along(helper_files)) {
  source(helper_files[i], local = TRUE, encoding = "UTF-8")$value
}

tool_name <- "MAX – Museum Analytics"
ui_files <- list.files(path = "./ui", pattern = "*.R")
if (length(ui_files) > 0) ui_files <- paste0("ui/", ui_files)

for (i in seq_along(ui_files)) {
  source(ui_files[i], local = TRUE, encoding = "UTF-8")$value
}

header <- dashboardHeader(
  title = a(img(src = paste0("logo_", gsub(" .*", "", tool_name), ".png"), 
    title = tool_name), href = "https://www.max.gwi.uni-muenchen.de/", 
    title = tool_name, target = "_blank")#,
  # tags$li(class = "dropdown", tooltipButton("header_bugreport_help", 
  #   fa_icon = icon("bug"), label = span(class = "label label-primary")))
)

sidebar <- dashboardSidebar(
  tags$head(tags$link(rel = "icon", type = "image/png", href = "favicon.ico")),
  tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "theme.css")),
  tags$head(tags$link(rel = "stylesheet", type = "text/css", 
    href = "https://fonts.googleapis.com/css?family=Roboto:300,400")),
  tags$head(tags$script(src = "script.js")),

  sidebarMenu(id = "sidebar-menu",
    menuItem("Dashboard", tabName = "dashboard", icon = icon("home")),
    menuItem("Preprocessing", tabName = "preprocessing", icon = icon("table")),
    menuItem("Visualisierung", tabName = "visualize", icon = icon("pie-chart")),
    
    tags$footer(class = "loaded-museums", 'data-toggle' = "tooltip", 
      'data-placement' = "auto top", title = get("sidebar_help"),
      htmlOutput("sidebar_objects")
    )
  )
)

body <- dashboardBody(
  useShinyjs(),
  
  div(id = "loading-content", loading_screen),

  hidden(div(id = "app-content", tabItems(panel_dashboard,
      panel_preprocessing, panel_visualisierung))
  ),

  tags$footer(class = "copyright",
    a(class = "link",
      p("Impressum"), title = "Impressum", target = "_blank",
      href = "https://www.max.gwi.uni-muenchen.de/impressum/"
    ),
    
    a(class = "link",
      p("Datenschutz"), title = "Datenschutz", target = "_blank",
      href = "https://www.max.gwi.uni-muenchen.de/datenschutz/"
    ),
    
    a(
      img(src = "logo_itg.png"),
      title = "IT-Gruppe Geisteswissenschaften", target = "_blank",
      href = "http://www.itg.uni-muenchen.de/index.html"
    ),

    a(
      img(src = "logo_lmu.png"),
      title = "Ludwig-Maximilians-Universität München", target = "_blank",
      href = "http://www.uni-muenchen.de/index.html"
    )
  )
)

dashboardPage(header, sidebar, body, title = tool_name)
