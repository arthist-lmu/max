# module user interface
browse_viewer_ui <- function(id) {
  ns <- NS(id)

  leafletOutput(ns("img_plot"), height = 500)
}

# module server logic
browse_viewer <- function(input, output, session) {
  values <- reactiveValues(image = NULL, points = NULL)

  observeEvent(input$img_plot_points, {
    values$points <- input$img_plot_points
  })

  output$img_plot <- renderLeaflet({
    leaflet() %>% onRender(
      get_overlay(values$image, isolate(values$points))
    )
  })

  list(
    set_data = function(data) {
      values$image <- data$image
      values$points <- data$points
    },
    get_points = function() {
      return(values$points)
    }
  )
}

get_overlay <- function(image, points = NULL) {
  if (is.null(points) | length(points) == 0) points <- ""

  if (is.list(points)) {
    points <- unname(unlist(points, recursive = TRUE))
    points <- split(points, ceiling(seq_along(points) / 2))

    points <- lapply(points, function(x) {
      glue("[{paste0(x, collapse = ', ')}]")
    })

    points <- paste0(unlist(points), collapse = ", ")
  }

  render_text <- glue(
    "function(el, x) {{
      var url = '{image}', pts = [{points}], map = this;
      L.tileLayer.iiif(url).addTo(map);

      var icon = new L.DivIcon({{
        className: 'custom-icon',
        iconSize: new L.Point(25, 25),
        iconAnchor: new L.Point(13, 13),
        html: '<span></span>'
      }})

      var drawn_markers = new L.FeatureGroup().addTo(map);
      var drawn_lines = new L.LayerGroup().addTo(map);

      var layer_control = new L.control.layers(null, {{
        '<i class=\"fa fa-comment-alt-dots\"></i>': drawn_markers,
        '<i class=\"fa fa-comment-alt-lines\"></i>': drawn_lines
      }});

      var draw_control = new L.Control.Draw({{
        edit: {{
          featureGroup: drawn_markers, edit: false, remove: false
        }},
        draw: {{
          polygon: false, polyline: false, circlemarker: false,
          marker: {{icon: icon}}, rectangle: false, circle: false
        }}
      }});

      map.addControl(draw_control); // feature console
      map.addControl(layer_control); // layer console
      map.addControl(new L.Control.Fullscreen());

      pts.forEach(function(pt, index) {{
        var latlng = map.unproject(pt, 3);
        var marker = new L.Marker(latlng);

        add_marker(marker);
      }})

      function export_markers() {{
        var pts = {{}}, i = -1; // initialize counter

        drawn_markers.eachLayer(function(marker) {{
          var pt = map.project(marker.getLatLng(), 3);
          i++; pts[i] = {{x: pt.x, y: pt.y}};
        }})

        Shiny.setInputValue(map.id + '_points', pts);
      }}

      function add_marker(marker) {{
        var marker_id = drawn_markers.getLayers().length;
        var section_id = marker_id - get_item_id() * 18;

        var custom_icon = new L.DivIcon({{
          className: 'custom-icon',
          iconSize: new L.Point(25, 25),
          iconAnchor: new L.Point(13, 13),
          html: '<span>' + section_id + '</span>'
        }})

        try {{
          drawn_markers.addLayer(marker);
          marker.dragging.enable();
          marker.setIcon(custom_icon);
        }} catch (error) {{
          // console.log(error);
        }}

        add_lines(); export_markers();

        marker.on('contextmenu', function(event) {{
          var items = drawn_markers.getLayers()

          if (items[items.length - 1] == this) {{
            this.bindPopup(
              '<i id=\"remove-marker\" class=\"fas ' +
              'fa-minus-circle\"></i>'
            ).openPopup();

            $(\"#remove-marker\").click(function() {{
              drawn_markers.removeLayer(marker);
              add_lines(); export_markers();
            }});
          }}
        }});

        marker.on('dragend', function(event) {{
          export_markers(); // console.log('edit');
        }})

        marker.on('drag', function(event) {{
          add_lines(); // console.log('drag');
        }})
      }}

      function add_lines() {{
        drawn_lines.clearLayers(); // delete all lines

        var n_markers = drawn_markers.getLayers().length;
        var layers = drawn_markers.getLayers();

        for (var i = 0; i <= get_item_id(); i++) {{
          if (n_markers - i * 18 > 0) {{
            var lines = [
              [4, 3], [3, 2], [2, 1], [7, 6], [6, 5], [5, 1],
              [1, 0], [16, 14], [14, 0], [17, 15], [15, 0],
              [10, 9], [9, 8], [8, 1], [13, 12], [12, 11],
              [11, 1] // connection points for estimation
            ]

            lines.forEach(function(line, index) {{
              if (i * 18 + line[0] < n_markers) {{
                var markers = [
                  layers[i * 18 + line[0]].getLatLng(),
                  layers[i * 18 + line[1]].getLatLng()
                ]

                var line = L.polyline(markers, {{
                  color: '#cd3a56', dashArray: '5, 5',
                  opacity: 0.75, weight: 2, smoothFactor: 1
                }});

                line.addTo(map).addTo(drawn_lines);
              }}
            }});
          }}
        }}
      }}

      function get_item_id() {{
        var marker_id = drawn_markers.getLayers().length;
        return Math.floor(parseInt(marker_id) / 18);
      }}

      map.on(L.Draw.Event.CREATED, function (event) {{
        if (event.layerType == 'marker') {{
          add_marker(event.layer);
        }}
      }});
    }}"
  )

  return(render_text)
}
