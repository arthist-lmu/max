library(yaml)
library(glue)
library(purrr)
library(dplyr)
library(readr)
library(tidyr)
library(tibble)
library(jsonlite)

read_ndjson <- function(values) {
  process <- function(x, progress = FALSE) {
    process_ <- function(x) {
      x <- tryCatch({
        x <- parse_json(enc2utf8(x), TRUE)[[1]] %>%
          enframe() %>% filter(nchar(name) > 1)

        if (nrow(x) > 1) {
          spread(x, name, value) %>% select(x$name)
        }
      }, error = function(event) {
        return(NULL) # display no error message
      })

      return(x)
    }

    if (progress) pb$tick()$print()

    return(process_(x))
  }

  tryCatch({
    file_path <- glue("{values$path}.rds")

    if (!file.exists(file_path)) {
      data_path <- "ndjson/{values$path}.ndjson"
      rows <- read_lines(file(glue(data_path)))

      pb <- progress_estimated(length(rows), min_time = 5)

      data <- map(rows, process) %>% bind_rows() %>%
        mutate_if(is.list, ~map(., paste, collapse = "; ")) %>%
        mutate_all(paste) %>% mutate_all(na_if, y = "")

      cols <- map(data, ~sum(is.na(.)) / length(.)) %>%
        enframe() %>% filter(value <= 0.75)

      data <- select(data, cols$name)
      saveRDS(data, file_path)
    } else {
      data <- readRDS(file_path)
    }

    data_info <- tibble(
      path = file_path, url = values$path,
      rows = nrow(data), cols = ncol(data),
      name = values$name, lang = values$lang
    )

    print(data_info)

    overview <- readRDS("data-sets.rds")
    overview <- bind_rows(overview, data_info)

    saveRDS(overview, "data-sets.rds")
  }, error = function(event) {
    print(glue("{values$name} {event}")); return(NA)
  })
}

saveRDS(tibble(), file = "data-sets.rds")
map(read_yaml("data-sets.yaml"), read_ndjson)
