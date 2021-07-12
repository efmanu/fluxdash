using Dash, DashCoreComponents, DashHtmlComponents

app = dash()

app.layout = html_div([
  dcc_store(id="data-memory", data=[]),
  dcc_interval(
      id="interval-component",
      interval=1*1000, # in milliseconds
      n_intervals=0
  ),
  html_div(id="live-update-text"),
  dcc_graph(id="live-update-graph")
])

callback!(app,
  Output("live-update-text", "children"), 
  Input("interval-component", "n_intervals"),
  ) do n
    return n
end

callback!(app,
  Output("data-memory", "data"), 
  Input("interval-component", "n_intervals"),
  State("data-memory", "data")
  ) do n, dt
    return push!(dt,rand())
end

callback!(app,
  Output("live-update-graph", "figure"),
  Input("interval-component", "n_intervals"),
  State("data-memory", "data")) do n,dt
    return Dict(
      "data" => [Dict(
        "x" => 1:n,
        "y" =>dt,
        "mode" => "line",
      ),  
      ]
    )
end
run_server(app, "0.0.0.0", 8050, debug=true)

