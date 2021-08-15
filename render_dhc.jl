function render_all()
    return dbc_container([
        dbc_card([
            dbc_cardheader(
                dbc_tabs(
                    [
                        render_data_tab(),
                        render_nn_tab(),
                        render_prediction_tab()                   
                    ],                
                    id="card-tabs",
                    card=true,
                    active_tab="tab-1",
                ),
            )        
        ])
    ],
    fluid=true
    )
end
function render_data_tab()
  return dbc_tab([
      dbc_cardbody([
          html_div([
              dcc_upload(
                  id="dflx-upload-data",
                  children=html_div([
                      "Drag and Drop or ",
                      html_a("Select Files")
                  ]),
                  style=Dict(
                      "width" => "100%",
                      "height" => "60px",
                      "lineHeight" => "60px",
                      "borderWidth" => "1px",
                      "borderStyle" => "dashed",
                      "borderRadius" => "5px",
                      "textAlign" => "center",
                      "margin" => "10px"
                  ),
                  # Allow multiple files to be uploaded
                  multiple=false
              ),                                    
              dbc_row([
                  dbc_col([html_div(id="dflx-output-data-upload")], md=6),
                  dbc_col([html_div(id="dflx-output-plot")], md=6),
              ],
              align="center",
              )
              
          ])
      ]),
  ],
  id="dflx-data-tab", label="Data", tab_id="tab-1")
  
end
function render_nn_tab()
  dbc_tab([
      html_div([
          dbc_row([
              dbc_col([
                  dbc_card([
                      dbc_cardbody(
                          [
                              html_h4("Select Inputs", className="card-title"),
                              html_div(id="dflx-input-name-list"),
                          ]
                      )
                  ])
                  ], 
                  md=2
              ),
              dbc_col([
                  dbc_card([
                      dbc_cardbody(
                          [
                              html_h4("Hidden Layers", className="card-title"),                  
                              html_div([                                                    
                                  dbc_row([
                                      dbc_col([html_i(id="dflx-add-hidden-layer",className="fa fa-plus-square fa-2x")],md=1,style=Dict("color" => "green")),
                                      dbc_col([html_i(id="dflx-remove-hidden-layer",className="fa fa-minus-square fa-2x")],md=1,style=Dict("color" => "red"))
                                  ], style=Dict("cursor" => "pointer"))
                              ]),
                              dcc_store(id="dflx-nn-layer-count"),
                              dbc_row(id = "dflx-hidden-layers"),                                                
                              html_div(id="dflx-nnlayer-count", style=Dict("display" => "none"))
                          ]
                      )
                  ])
                  ], 
                  md=8
              ),
              dbc_col([
                  dbc_card([
                      dbc_cardbody(
                          [
                              html_h4("Select Outputs", className="card-title"),
                              html_div(id="dflx-output-name-list"),
                          ]
                      )
                  ])
                  ], 
                  md=2
              )
          ],
          align="center",
          ),
          dbc_row([
              dbc_col([
                  daq_numericinput(id="dflx-nntrain-percent", label="Percentage of training dataset", value=70, max = 99, min = 1)
              ]),
              dbc_col([
                  daq_numericinput(id="dflx-nntrain-epoch", label="Epochs", value=4, min = 1, max=10000)
              ]),
              dbc_col([
                  dbc_button(
                      "Start Training", id="dflx-nnlayer-submit",
                      color="success", className="mr-1",
                      style = Dict(
                          "margin-top" => "20px",
                          "display" => "flex",
                          "justify-content" => "center"
                      )
                  ),
              ])
          ]),                                  
      ]),
      html_div(id="dflx-training-updates")                          
  ],
  style = Dict("margin-top" => "20px"),
  id="dflx-nn-tab", label="NN Config", tab_id="tab-2", disabled="true")
end
function render_prediction_tab()
  return dbc_tab(id="dflx-pred-tab", label="Prediction", tab_id="tab-3", disabled="true") 
end
function render_table(df, filename; n_rows = 1)
  df = df[!, Not("id")]
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
  row_names = row_names[row_names .!= "id"]
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
    dcc_graph(id="dflx-plot-graph", figure =  render_graph(df, row_names[end], row_names[end]))    
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
              interval=100, # in milliseconds
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
function render_testing(m, X_test,y_test)
  yₚ, maerr, mserr, crenpy = test_nn(m,X_test,y_test)
  return html_div("test finished error is: $maerr")
end