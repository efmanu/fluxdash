using Dash, DashCoreComponents, DashHtmlComponents

app = dash()

app.layout = html_div([
  dcc_interval(
      id="interval-component",
      interval=1*1000, # in milliseconds
      n_intervals=0
  ),
  html_div(id="live-update-text"),
  dcc_graph(id="live-update-graph")
])


callback!(app,
  Output("live-update-graph", "figure"),
  Input("interval-component", "n_intervals"),
  State("live-update-graph", "figure")) do n, stg
    if !(stg isa Nothing)      
      if !(stg[1][1].x isa Nothing)
        append!(stg[1][1].x, stg[1][1].x[end]+1)
        append!(stg[1][1].y, 2*rand()+3)
      end      
    else  
      stg = [[(x = [1], y = [2*rand()+3], mode = "line")]]    
    end
    return stg
end
run_server(app, "0.0.0.0", 8050, debug=true)

