req_and_assign <- function(object, name) {
  req(object)
  assign(name, object, pos = 1L)
}

multiple_gsub <- function(object, terms) {
  for (term in terms) {
    object <- gsub(term[1], term[2], object)
  }
  
  return(object)
}

prettify_number <- function(object) {
  return(format(object, big.mark = ".", decimal.mark = ","))
}

hex_to_rgba <- function(x) {
  x <- col2rgb(x)
  x <- apply(x, 2, function(x) {paste(x, collapse = ", ")})
  x <- paste0("rgba(", x, ", 0.65)")
  
  return(x)
}

is_true <- function(object) {
  value <- FALSE
  
  if (!is.null(object)) {
    if (object) {
      value <- TRUE
    }
  }
  
  return(value)
}

is_empty <- function(object) {
  value <- FALSE
  
  if (!is.null(object)) {
    if (object != "" & !is.na(object)) {
      value <- TRUE
    }
  }
  
  return(value)
}

get_histogram <- function(data, breaks = seq(1300, 2020, 10)) {
  return(hist(data, breaks = breaks, plot = FALSE)$counts)
}

send_mail <- function(from = "<max@cereality.net>", to = "<max@cereality.net>", 
    subject, body, server = "w008e21f.kasserver.com") {
  sendmail(from, to, subject, body, control = list(smtpServer = server))
}

customTryCatch <- function(expr) {
  warn <- err <- NULL
  
  withCallingHandlers(
    tryCatch(expr, error = function(e) {
      err <<- e
      NULL
    }), warning = function(w) {
      warn <<- w
      invokeRestart("muffleWarning")
    }
  )
  
  return(list(warning = warn, error = err))
}