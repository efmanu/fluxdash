function render_table(df, filename; n_rows = 1)
  return html_div([
    html_h3(filename),
    DashTable.dash_datatable(
      data = Dict.(pairs.(eachrow(df))),
      columns=[Dict("name" =>c, "id" => c) for c in names(df)],
      virtualization=true,
      fixed_rows=Dict("headers" => true),
      style_cell=Dict(
          "minWidth" =>  95, "maxWidth" =>  95, "width" =>  95
      ),
      style_table=Dict("height" => 300),  # default is 500
      page_action="none"
  )])
end
function render_graph_title(df)
  row_names = names(df) 
  return html_div([
    html_h5("Plots"),
    dbc_row([
      dbc_col([
        render_single_graphtitle(row_names)
      ],
      md=6),
      dbc_col([
        render_mult_graphtitle(row_names)
      ],
      md=6)
    ],
    align="center"
    ),    
    dcc_graph(id="dflx-plot-graph", figure =  render_graph(df, row_names[ncol(df)], row_names[ncol(df)]))    
  ])
end
function render_graph(df, x_xolumn, y_columns)
  if !(y_columns isa Vector)
    dt = [Dict(
      "x" => df[!,Symbol(x_xolumn)], 
      "y" => df[!,Symbol(y_columns)], 
      "type" => "scatter",
      "mode" => "markers"
    )]
  else
        dt = [Dict(
      "x" => df[!,Symbol(x_xolumn)], 
      "y" => df[!,Symbol(yc)], 
      "type" => "scatter",
      "mode" => "markers"
    ) for yc in y_columns]
  end
  return Dict(
      "data" => dt,
      "layout" => Dict(
          "title" => "Dash Data Visualization"
      )
  )
end
function render_mult_graphtitle(row_names;id_val="dflx-graph-dropdown-y")
  return dcc_dropdown(
    id=id_val,
    options = [Dict("label" => rn, "value" => rn) for rn in row_names],
    value = row_names[end],
    multi=true
  )
end
function render_single_graphtitle(row_names;id_val="dflx-graph-dropdown-x")
  return dcc_dropdown(
    id=id_val,
    options = [Dict("label" => rn, "value" => rn) for rn in row_names],
    value = row_names[end],
    multi=false
  )
end

function render_nn_layer(n_click)
  return [dbc_col([
        dbc_card([
            dbc_cardbody(
                [
                    html_h4("Layer $i", className="card-title"),
                    daq_numericinput(label="Output count", value=2, max = 10000, min = 1)
                ]
            )
        ])
        ], 
        md=2
    ) for i in 1:n_click]
  
end
function render_training()
  return dbc_row([
      dbc_col([
          dcc_interval(
              id="interval-component",
              interval=1000, # in milliseconds
              n_intervals=0,
              disabled=false
          ),
          dcc_graph(id="live-update-graph")
      ]),
      dbc_col([
         html_div(id="dflx-testing-section")
      ]),
  ])
end
function render_testing(trained_model, df, in_labels, out_labels)
  _, X_test, _, y_test = format_nn_data(df, in_labels, out_labels)
  yₚ, err, maerr, mserr, crenpy = test_nn(m,X_test,y_test)
  return dbc_row([
      dbc_col([
          dcc_interval(
              id="dflx-interval-testing",
              interval=100, # in milliseconds
              n_intervals=0
          ),
          dcc_graph(id="live-tegraph")
      ]),
      dbc_col([
         dbc_gaph 
      ]),
  ])
end