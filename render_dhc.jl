function render_table(df, filename; n_rows = 1)
  table_header = 
     html_thead(
       html_tr([
         html_th(nm) for nm in names(df)
       ])
     )
  table_body =  html_tbody([
      html_tr([html_td(df[nr,nc]) for nc in 1:ncol(df)]) for nr in 1:n_rows
    ])
    return html_div([
      html_h5("Displaying first $n_rows rows of $filename"),
      dbc_table([table_header , table_body], bordered=true)
  ],  
  )
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
                    daq_numericinput(label="Output count", value=2)
                ]
            )
        ])
        ], 
        md=2
    ) for i in 1:n_click]
  
end