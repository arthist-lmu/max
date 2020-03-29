get_random_id <- function(n = 10) {
  random_id <- as.character(runif(1, min = 0, max = 100))

  return(strtrim(digest(paste0(Sys.time(), random_id)), n))
}

get_help <- function(fct, pkg, html = TRUE, collapse = TRUE) {
  if (require(pkg, character.only = TRUE)) {
    help_text <- utils:::.getHelpFile(help(fct, package = (pkg)))

    if (html) help_text <- capture.output(tools::Rd2HTML(help_text))
    if (collapse) help_text <- paste0(help_text, collapse = "\n")

    return(help_text)
  }
}

get_title <- function(html_text) {
  return(str_match(html_text, pattern = "<h2>(.*?)</h2>")[, 2])
}

get_section <- function(html_text, section) {
  html_text <- gsub(glue(".*<h3>{section}</h3>"), "", html_text)

  return(trimws(gsub("<h3>.*", "", html_text), which = "both"))
}

load_help <- function(fct, pkg) {
  html_text <- get_help(fct, pkg, TRUE, collapse = TRUE)

  content <- gsub(".*<body>", "", html_text)
  # content <- gsub("<h3>See Also</h3>.*", "", content)
  # content <- gsub("<h3>Examples</h3>.*", "", content)

  content <- glue("<div class='help'>{content}</div>")
  content <- HTML(trimws(content, which = "both"))

  return(list(title = get_title(html_text), content = content))
}

get_pkg <- function(fct) {
  return(environmentName(environment(get(fct))))
}

get_args <- function(name, ...) {
  formals(name) %>% map(capture.output) %>%
    enframe(name = "name", value = "default") %>%
    mutate(default = gsub(".*] ", "", default)) %>%
    mutate(default = str_remove_all(default, '"')) %>%
    mutate(
      optional = ifelse(nchar(default) == 0, NA, "Optional"),
      value = "" # placeholder, will be set by the user
    ) %>%
    fill(optional, .direction = "down") %>%
    replace_na(list(optional = ""))
}

call_args <- function(args, arg_data = NULL) {
  args <- paste(args, sep = "", collapse = ", ")
  args <- gsub("... = ", "", args, fixed = TRUE)
  args <- eval(parse(text = glue("alist({args})")))

  .out <- c(arg_data, args)
}

read_fcts <- function(file) {
  fcts <- bind_rows(read_yaml(file)$functions) %>%
    mutate(html = pmap(list(name, package), get_help)) %>%
    mutate(title = map_chr(html, get_title)) %>%
    mutate(args = map(name, get_args, split = FALSE)) %>%
    mutate(label = glue("<code>{name}</code> {title}")) %>%
    mutate(label = glue("<div title='{title}'>{label}</div>"))

  return(select(fcts, -c(html, title)) %>% arrange(name))
}

customTryCatch <- function(expr) {
  warn <- err <- NULL

  withCallingHandlers(
    tryCatch(expr, error = function(e) {
      err <<- e; return(NULL)
    }), warning = function(w) {
      warn <<- c(warn, list(w))
      invokeRestart("muffleWarning")
    }
  )

  return(list(warning = warn, error = err))
}

import_csv <- function(file, ...) {
  data <- readr::read_csv(file$datapath)

  return(data)
}

import_json <- function(file, ...) {
  data <- jsonlite::fromJSON(txt = file$datapath) %>%
    purrr::flatten() %>% map_if(is_list, as_tibble) %>%
    map_if(is_tibble, list) %>% bind_cols()

  return(data)
}

import_rds <- function(file, ...) {
  data <- readRDS(file$datapath)

  return(data)
}

import_xls <- function(file, ...) {
  data <- readxl::read_excel(file$datapath)

  return(data)
}

import_r <- function(file, ...) {
  # TODO

  return(data)
}

get_ext <- function(x, convert = FALSE) {
  ext <- str_split(tolower(x), "\\.")
  ext <- unlist(ext) %>% last()

  if (convert) {
    ext <- case_when(
      ext == "txt" ~ "csv",
      ext == "xlsx" ~ "xls",
      !is.na(ext) ~ ext
    )
  }

  return(ext)
}
