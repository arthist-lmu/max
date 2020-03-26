# devtools::install_github("rstudio/htmltools")

# import libraries
library(DT)
library(zip)
library(glue)
library(yaml)
library(shiny)
library(purrr)
library(dplyr)
library(tidyr)
library(readr)
library(digest)
library(tibble)
library(plotly)
library(stringr)
library(ggplot2)

# set seed
set.seed("20200316")

# load utilities
source("utils/utils.R")
source("utils/ui-utils.R")

# load modules
source("modules/mod_header.R")
source("modules/mod_header_export.R")
source("modules/mod_header_import.R")

source("modules/mod_preprocess.R")
source("modules/mod_visualize.R")

source("modules/mod_history.R")
source("modules/mod_history_import.R")

# by default, the maximum file size is limited to 5 MB
options(shiny.maxRequestSize = 100 * 1024 ^ 2)
