using CSV: Options
using Dash, DashBootstrapComponents, DashHtmlComponents, DashCoreComponents
using DashTable
using Core: Typeof
using Base64, Dates, CSV, DataFrames
using PlotlyJS

include("utils.jl")
include("render_dhc.jl")
app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP], 
    suppress_callback_exceptions=true)

app.layout = html_div([
    dcc_store(id="dflx-data-memory"),
    dbc_card([
        dbc_cardheader(
            dbc_tabs(
                [
                    dbc_tab(label="Tab 1", tab_id="tab-1"),
                    dbc_tab(label="Tab 2", tab_id="tab-2"),                    
                ],                
                id="card-tabs",
                card=true,
                active_tab="tab-1",
            ),
        ),
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
                dbc_container([
                    dbc_row([
                        dbc_col([html_div(id="dflx-output-data-upload")], md=6),
                        dbc_col([html_div(id="dflx-output-plot")], md=6),
                    ],
                    align="center",
                    ),
                    dbc_row([
                        dbc_col([html_div(id="dflx-show-msg")], md=6)
                    ])
                ],
                fluid=true
                )
            ])
        ]),
    ])
])
  
  
callback!(
    app,
    Output("dflx-data-memory", "data"),
    Output("dflx-output-data-upload", "children"),
    Output("dflx-output-plot", "children"),
    Input("dflx-upload-data", "contents"),
    State("dflx-upload-data", "filename"),
) do contents, filename
    if (contents isa Nothing)
        throw(PreventUpdate())
    else
        df = parse_contents(contents, filename)
        return_data = render_table(df, filename; n_rows = 5)
        return_graph = render_graph_title(df)
        return df, return_data, return_graph
    end
end

callback!(app,
    Output("dflx-plot-graph", "figure"),
    Input("dflx-graph-dropdown-x", "value"),
    Input("dflx-graph-dropdown-y", "value"),
    State("dflx-data-memory", "data")    
) do valuex, valuey, df
    new_tp = DataFrame(;zip(Tuple(Symbol.(df.colindex.names)), Tuple(df.columns))...)
    return  render_graph(new_tp, valuex, valuey)
end

run_server(app, "0.0.0.0", 8050, debug=true)