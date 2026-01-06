require(data.table)
require(sendmailR)
# require(googlesheets)
require(htmltools)
require(stringi)
require(RMySQL)
require(tidyverse)

helper_files <- list.files(path = "./helpers", pattern = "*.R")
helper_files <- paste0("helpers/", helper_files)

for (i in seq_along(helper_files)) {
  source(helper_files[i], local = TRUE, encoding = "UTF-8")$value
}

# by default, the maximum file size is limited to 5 mb per file
max_file_size <- 100
options(shiny.maxRequestSize = max_file_size * 1024 ^ 2)

shinyServer(function(input, output, session) {
  server_files <- list.files(path = "./server", pattern = "*.R")
  if (length(server_files) > 0) server_files <- paste0("server/", server_files)
  
  for (i in seq_along(server_files)) {
    source(server_files[i], local = TRUE, encoding = "UTF-8")$value
  }

  shinyjs::hide(id = "loading-content", anim = TRUE, animType = "fade")    
  shinyjs::show(id = "app-content")
  
  # show modal for first steps
  text <- fread("data/first_steps.txt", encoding = "UTF-8", sep = ";",
    quote = "", blank.lines.skip = TRUE, header = FALSE)
  text <- paste(text[[1]], collapse = "")
  show_modal(text, title = "Erste Schritte", confirm = FALSE)
})