# devtools::install_github("rstudio/htmltools")

# import libraries
library(DT)
library(zip)
library(DBI)
library(glue)
library(yaml)
library(iiifr)
library(rjson)
library(shiny)
library(purrr)
library(dplyr)
library(tidyr)
library(readr)
library(RMySQL)
library(digest)
library(tibble)
library(plotly)
library(leaflet)
library(stringr)
library(ggplot2)
library(RSQLite)
library(urltools)
library(shinytree)
library(data.table)
library(htmlwidgets)
library(shinygallery)

# set seed
set.seed("20200316")

# load utilities
source("utils/utils.R")
source("utils/ui-utils.R")

# load modules
source("modules/mod_header.R")
source("modules/mod_header_export.R")
source("modules/mod_header_import.R")

source("modules/mod_browse.R")
source("modules/mod_browse_tree.R")
source("modules/mod_browse_chart.R")
source("modules/mod_browse_viewer.R")
source("modules/mod_browse_gallery.R")
source("modules/mod_browse_switch.R")

source("modules/mod_preprocess.R")
source("modules/mod_visualize.R")

source("modules/mod_history.R")
source("modules/mod_history_import.R")

options(shiny.maxRequestSize = 100 * 1024 ^ 2)
options(shiny.fullstacktrace = TRUE)

FILE_IC <- "data/iconclass.sqlite"
FILE_MD <- "data/metadata.sqlite"
FILE_ID <- "data/index.sqlite"
