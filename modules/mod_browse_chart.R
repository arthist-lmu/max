# module user interface
browse_chart_ui <- function(id) {
  ns <- NS(id)

  plotlyOutput(ns("plot"), height = "400px")
}

# module server logic
browse_chart <- function(input, output, session) {
  lang_data <- fromJSON(file = "data/browse_en.json")
  values <- reactiveValues(data = NULL)

  output$plot <- renderPlotly({
    req(values$data, nrow(values$data) > 0)

    plot_object <- ggplot(
        values$data, aes(
          x = date, fill = ifelse(
            test = id, yes = lang_data$plotLegendTrue,
            no = lang_data$plotLegendFalse
          )
        )
      ) +
      geom_histogram(
        aes(y = stat(density * width)), binwidth = 10,
        position = "identity", alpha = 0.75
      ) +
      scale_fill_manual(values = c("#cd3a56", "#953269")) +
      labs(x = lang_data$plotXLabel, y = "", fill = "") +
      theme(
        legend.position = c(0, 1),
        panel.border = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.background = element_rect("white"),

        axis.ticks = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        plot.margin = unit(c(0, 0, 5, 0), "mm"),

        legend.title = element_blank(),
        legend.justification = "left",
        legend.direction = "horizontal",
        legend.spacing.x = unit(0.4, "cm"),
        legend.text = element_text(size = 12)
      ) +
      scale_x_continuous(breaks = seq(1000, 2100, 100)) +
      scale_y_continuous(
        breaks = scales::pretty_breaks(n = 8)
      )

    plot_object <- ggplotly(plot_object)

    for (i in seq_along(plot_object$x$data)) {
      plot_text <- plot_object$x$data[[i]]$text
      plot_text <- lapply(plot_text, lapply, convert)

      plot_object$x$data[[i]]$text <- replace_multiple(
        unlist(plot_text), c("density \\* width", "date"),
        c(lang_data$plotYLabel, lang_data$plotXLabel)
      )
    }

    ggplotly(plot_object, tooltip = "text") %>%
      layout(
        legend = list(
          orientation = "h", x = 0.02, y = 0.75, font = list(
            family = "Roboto", size = 14, color = "#333"
          )
        ),
        hoverlabel = list(
          bordercolor = "#fff", align = "left", font = list(
            family = "Roboto", size = 12, color = "#fff"
          )
        ),
        xaxis = list(title = list(standoff = 20))
      ) %>%
      style(legendgroup = NULL) %>%
      config(
        displaylogo = FALSE, showSendToCloud = FALSE,
        modeBarButtonsToRemove = c(
          "zoom2d", "pan2d", "select2d", "autoScale2d",
          "lasso2d", "toggleSpikelines"
        )
      )
  })

  list(
    set_data = function(data) {
      values$data <- data[data$date %in% 1000:2020, ]
    }
  )
}

convert <- function(string) {
  string <- str_split(string, pattern = "<br />")[[1]]
  string <- str_split(string[1:2], ": ", simplify = FALSE)

  if (length(string) > 1) {
    string[[1]][2] <- round(as.numeric(string[[1]][2]) * 100, 4)
    string[[1]][2] <- glue("{string[[1]][2]} %")
  }

  string <- lapply(string, paste, collapse = ": ")

  return(paste0(unlist(string), collapse = "<br />"))
}
