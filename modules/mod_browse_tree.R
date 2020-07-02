# module user interface
browse_tree_ui <- function(id) {
  ns <- NS(id)

  treeOutput(ns("show"), height = "400px")
}

# module server logic
browse_tree <- function(input, output, session) {
  examples <- reactiveValues(data = NULL, codes = 0:9)

  values <- reactiveValues(
    data = get_initial(FILE_IC), url = NULL
  )

  observe({
    codes <- input$show_checked_id

    if (!is.logical(all.equal(examples$codes, codes))) {
      examples$data <- get_examples(codes, FILE_IC)
      examples$codes <- codes # current value
    }
  })

  observeEvent(input$show_search, {
    search <- input$show_search

    if (nchar(search) == 0) {
      values$data <- get_initial(FILE_IC)
      examples$data <- get_examples(0:9, FILE_IC)
    } else {
      codes <- search_codes(search, FILE_IC)

      if (!is.null(codes)) {
        codes <- get_codes(codes, FILE_IC)

        children_1 <- get_children(codes, FILE_IC)
        children_2 <- get_children(children_1, FILE_IC)

        values$data <- c(
          values$data, codes, children_1,
          children_2, values$data[1]
        )
      } else {
        values$data <- get_initial(FILE_IC)
        examples$data <- get_examples(0:9, FILE_IC)

        show_modal(
          HTML("<p>Your search didn't return any results.</p>"),
          size = "s" # small modal without close button
        )
      }
    }
  })

  observeEvent(input$show_opened_id, {
    children <- input$show_opened_children
    codes <- names(values$data) %in% children

    children <- get_children(values$data[codes], FILE_IC)
    codes <- names(children) %in% names(values$data)

    if (sum(!codes) > 0) {
      values$data <- c(values$data, children[!codes])
    }
  })

  output$show <- renderTree({
    tree(
      unique(values$data[order(names(values$data))]),
      plugins = c("search", "wholerow", "checkbox"),
      options = list(
        "themes" = list("dots" = FALSE, "icons" = FALSE),
        "check_callback" = TRUE, "scrollbar" = TRUE
      )
    )
  })

  outputOptions(output, "show", suspendWhenHidden = FALSE)

  list(
    set_url = function(url) {
      if (!is.na(url)) url <- glue('"{url}"')
      values$url <- get_sources(url, FILE_MD, TRUE)
    },
    get_data = function() {
      if (!is.null(values$url)) {
        indices <- examples$data %in% values$url
        return(examples$data[indices])
      }

      return(examples$data)
    }
  )
}

get_codes <- function(codes, file) {
  get_code <- function(code, connect) {
    value <- tryCatch(
      {
        query <- sprintf(
          "SELECT * FROM database WHERE code = '%s'",
          gsub("'", "''", code, ignore.case = TRUE)
        )

        result <- DBI::dbGetQuery(connect, query)

        parent <- rjson::fromJSON(result[["p"]])
        parent <- tail(parent, n = 1)

        if (length(parent) == 0) parent <- "#"

        children <- rjson::fromJSON(result[["c"]])
        text <- rjson::fromJSON(result[["txt"]])$en
        n_ex <- rjson::fromJSON(result[["n_ex"]])

        text <- glue("<code>{code}</code> {text}")

        result <- list(
          id = code, parent = parent,
          children = children, text = text
        )

        if (n_ex == 0) {
          result[["state"]] <- list("disabled" = TRUE)
        }

        return(result)
      }, error = function(error) {
        return(NULL)
      }, warning = function(warning) {
        return(NULL)
      }
    )

    return(value)
  }

  connect <- DBI::dbConnect(RSQLite::SQLite(), file)

  results <- sapply(
    codes, get_code, connect = connect,
    simplify = FALSE, USE.NAMES = TRUE
  )

  DBI::dbDisconnect(connect)
  names(results) <- codes

  return(results)
}

search_codes <- function(term, file) {
  connect <- DBI::dbConnect(RSQLite::SQLite(), file)
  term <- gsub("'", "''", term) # escape characters

  query <- glue(
    "SELECT code, p, c FROM database WHERE txt like '%",
    "{term}%' OR code = '{term}' COLLATE NOCASE ORDER",
    " BY code LIMIT 100"
  )

  results <- DBI::dbGetQuery(connect, query)
  DBI::dbDisconnect(connect)

  if (nrow(results) > 0) {
    parents <- from_json(results[[2]])
    children <- from_json(results[[3]])

    results <- c(unlist(parents), results[[1]])
    results <- c(results, unlist(children))

    return(unique(results))
  }

  return(NULL)
}

get_examples <- function(codes, file) {
  if (is.null(codes)) codes <- 0:9

  codes <- gsub("\\.\\.\\.\\)$", "", codes)
  codes <- gsub("'", "''", codes, fixed = TRUE)

  codes <- glue("code like '{codes}%'")
  codes <- paste(codes, collapse = " OR ")

  connect <- DBI::dbConnect(RSQLite::SQLite(), file)
  query <- glue("SELECT ex FROM database WHERE {codes}")

  results <- DBI::dbGetQuery(connect, query)
  results <- from_json(results[[1]])

  DBI::dbDisconnect(connect)

  return(unique(unlist(results, TRUE, FALSE)))
}

get_children <- function(codes, file) {
  if (length(codes) > 0) {
    results <- lapply(codes, function(x) x$children)

    return(get_codes(unlist(results), file))
  }
}

get_initial <- function(file) {
  codes <- get_codes(as.character(0:9), file)
  children <- get_children(codes, file)

  return(c(codes, children))
}
