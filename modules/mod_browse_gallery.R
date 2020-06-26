# module user interface
browse_gallery_ui <- function(id) {
  ns <- NS(id)

  galleryOutput(ns("show"), height = "150px")
}

# module server logic
browse_gallery <- function(input, output, session) {
  ns <- session$ns; box_options <- c("details")#, "add")

  chart <- callModule(browse_chart, id = "chart")
  viewer <- callModule(browse_viewer, id = "viewer")

  values <- reactiveValues(
    examples = NULL, created = NULL, filter = NULL,
    page_range = c(1, 100), page_id = NA, per_page = 100,
    data = NULL, user = NULL, click_event = NULL
  )

  lang_data <- fromJSON(file = "data/browse_en.json")
  valid_data <- readRDS("data/paths.rds")

  observeEvent(values$examples, {
    session$sendCustomMessage(ns("reset"), Sys.time())

    page_range <- c(values$per_page, length(values$examples))
    page_range <- get_seq(c(1, min(page_range, na.rm = TRUE)))

    values$data <- get_sources(values$examples[page_range], FILE_MD)

    values$page_range <- c(1, max(page_range, na.rm = TRUE))
    values$page_id <- 1; values$filter <- NULL
  })

  observeEvent(input$show_click_value, {
    if (!is.null(input$show_click_id)) {
      resource_id <- input$show_click_resource_id
      index <- match(resource_id, values$data$id)

      resource <- values$data[index, ]

      if (input$show_click_value == "details") {
        title <- unique(unlist(resource$title), FALSE)
        if (is.na(title[1])) title <- lang_data$titleLabel

        if (is.na(resource$subtitle[[1]][1])) {
          resource$subtitle <- lang_data$subtitleLabel
        }

        metadata <- tagList(
          get_line(lang_data$alttitle,   title[-1],           "text"),
          get_line(lang_data$date,       resource$date,       "text"),
          get_line(lang_data$subtitle,   resource$subtitle,   "text"),
          get_line(lang_data$style,      resource$style,      "text"),
          get_line(lang_data$type,       resource$type,       "text"),
          get_line(lang_data$themes,     resource$themes,     "code"),
          get_line(lang_data$collection, resource$collection, "text")
        )

        if (file.exists(FILE_ID)) {
          indices <- get_similar(resource$id, FILE_ID)
          indices <- match(indices, valid_data$id)

          metadata <- tagAppendChild(
            metadata, get_line(lang_data$similar, unlist(
              valid_data$src[indices[1:9]], FALSE), "img")
          )
        }

        modal_content <- tagList(
          tags$div(
            class = "left", browse_viewer_ui(ns("viewer")),
            tags$span(
              tags$a(
                href = resource$url, title = "Copyright",
                target = "_blank", icon("copyright"),

                tags$code(url_parse(resource$url[[1]])[2])
              )
            )
          ),
          tags$div(class = "right", tags$h3(title[1]), metadata)
        )

        show_modal(modal_content, class = "modal-image")
      } else {

      }
    }
  })

  observeEvent(input$show_page_id, {
    values$page_id <- input$show_page_id
  })

  observeEvent(input$show_per_page, {
    values$per_page <- input$show_per_page
  })

  observeEvent(input$show_click_image, {
    image <- gsub(
      "full.*", "info.json", input$show_click_image[3],
      perl = FALSE, ignore.case = TRUE, fixed = FALSE
    )

    viewer$set_data(list(image = image))
  })

  observeEvent(input$show_page_range, {
    indices <- get_seq(input$show_page_range)

    if (!is.null(values$filter)) {
      examples <- values$filter[indices]
    } else {
      examples <- values$examples[indices]
    }

    indices <- !(examples %in% values$data$id)

    if (sum(indices) > 0) {
      data <- get_sources(examples[indices], FILE_MD)
      values$data <- rbindlist(list(values$data, data))
    }

    values$page_range <- input$show_page_range
  })

  observeEvent(input$show_filter, {
    filter <- NULL

    if (nchar(trimws(input$show_filter)) > 0) {
      examples <- get_sources(input$show_filter, FILE_MD, TRUE)

      if (length(examples) > 0) {
        page_range <- c(values$per_page, length(examples))
        values$page_range <- c(1, min(page_range))

        filter <- examples[examples %in% values$examples]
        indices <- !(filter %in% values$data$id)

        if (sum(indices) > 0) {
          data <- get_sources(filter[indices], FILE_MD)
          values$data <- rbindlist(list(values$data, data))
        }
      } else {
        # TODO: modal "no results"
      }
    }

    values$filter <- filter
    values$page_id <- 1
  })

  observeEvent(input$show_click_icon, {
    if (input$show_click_icon == "analytics") {
      if (!is.null(values$filter)) {
        data <- valid_data[valid_data$id %in% values$filter, ]
      } else {
        data <- valid_data[valid_data$id %in% values$examples, ]
      }

      if (nrow(data) == nrow(valid_data)) {
        values$created <- data; values$created$id <- TRUE
      } else {
        values$created <- rbindlist(list(valid_data, data))

        values$created$id <- c(
          rep(FALSE, nrow(valid_data)), rep(TRUE, nrow(data))
        )
      }

      show_modal(
        browse_chart_ui(ns("chart")), class = "modal-chart"
      )
    }
  })

  observeEvent(values$created, {
    chart$set_data(values$created)
  })

  output$show <- renderGallery({
    if (!is.null(values$data)) {
      if (!is.null(values$filter)) {
        examples <- values$filter[get_seq(values$page_range)]
        number_objects <- length(values$filter) # reduced count
      } else {
        examples <- values$examples[get_seq(values$page_range)]
        number_objects <- length(values$examples) # full count
      }

      data <- values$data[values$data$id %in% examples, ]

      gallery_options <- list(
        "startPage" = isolate(values$page_id),
        "perPage" = isolate(values$per_page),
        "limits" = values$page_range,

        "numberObjects" = number_objects,
        "infoLabel" = lang_data$infoLabel,
        "titleLabel" = lang_data$titleLabel,
        "selectLabel" = lang_data$selectLabel,
        "subtitleLabel" = lang_data$subtitleLabel,
        "search" = TRUE, "buttons" = list("analytics")
      )

      if ("add" %in% box_options) {
        gallery_options$addLabel <- lang_data$addLabel
        gallery_options$draggable <- TRUE # move around
      }

      if ("remove" %in% box_options) {
        gallery_options$removeLabel <- lang_data$removeLabel
      }

      if ("details" %in% box_options) {
        gallery_options$detailsLabel <- lang_data$detailsLabel
      }

      gallery(data, options = gallery_options)
    }
  })

  observeEvent(viewer$get_points(), {

  })

  outputOptions(output, "show", suspendWhenHidden = FALSE)

  list(
    set_data = function(data) {
      valid_ids <- match(data, valid_data$id)
      values$examples <- valid_data$id[valid_ids]
    },
    set_user = function(user) {
      values$user <- user
    },
    set_url = function(url) {
      values$url <- url
    }
  )
}

get_sources <- function(terms, file, reduced = FALSE) {
  if (!is.null(terms) & !is.na(terms[1])) {
    connect <- DBI::dbConnect(RSQLite::SQLite(), file)

    query <- paste0(
      "SELECT * FROM database WHERE database MATCH '",
      paste(terms, collapse = " OR "), "'"
    )

    results <- DBI::dbGetQuery(connect, query)
    DBI::dbDisconnect(connect)

    if (reduced) {
      results <- unlist(results$id, FALSE, FALSE)
    } else if (nrow(results) > 0) {
      i <- results[, -1] == "[]"; results[, -1][i] <- NA
      results[, -1][!i] <- from_json(results[, -1][!i])

      colnames(results)[c(2, 5)] <- c("path", "subtitle")

      results$path <- unlist(results$path, TRUE, FALSE)
      results$path <- get_iiif(results$path, 300)
    }

    return(results)
  }
}

get_similar <- function(id, file) {
  connect <- DBI::dbConnect(RSQLite::SQLite(), file)

  query <- glue(
    "SELECT similar FROM database WHERE id = '{id}'"
  )

  results <- DBI::dbGetQuery(connect, query)
  DBI::dbDisconnect(connect)

  return(from_json(results[[1]])[[1]])
}

get_line <- function(key, value, type = "text") {
  value <- gsub("\\s*-\\s*", "-", trimws(unlist(value)))
  value <- value[!is.na(value) & nchar(value) > 0]

  if (length(value) > 0) {
    value <- strip(iconv(value, "UTF-8", to = "WINDOWS-1252"))

    if (type == "code") {
      value <- sapply(value[order(value)], code, simplify = FALSE)
    } else if (type == "img") {
      value <- glue("<img src='{get_iiif(value, 200)}'>")
      value <- HTML(paste(value, collapse = ""))
    } else {
      value <- paste(value, collapse = "; ") # reduce to one line
    }

    value <- tagList(tags$div(glue("{key}: ")), tags$div(value))

    return(tags$div(class = "line", value))
  }
}

get_iiif <- function(path, width = 300) {
  url <- paste0(
    "https://iiif.dhvlab.org/lmu/iart/{path}/",
    "full/!{width},{width}/0/default.jpg"
  )

  path <- gsub("\\.gif", ".jpg", path)

  return(glue(url, .na = ""))
}
