using CSV: Options
using Dash, DashBootstrapComponents, DashHtmlComponents, DashCoreComponents
using DashTable, DashDaq
using Core: Typeof
using Base64, Dates, CSV, DataFrames
using PlotlyJS
using Random, StatsBase
using Flux
using Flux: Data.DataLoader

include("utils.jl")
include("render_dhc.jl")
include("generate_nn.jl")
external_stylesheets = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"

chn = Channel{Tuple{Float64, Int, Chain}}(Inf)
m = nothing
in_labels = nothing
out_labels = nothing
X_test = nothing
y_test = nothing
app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP,external_stylesheets], 
    suppress_callback_exceptions=true)

app.layout = html_div([
    dcc_store(id="dflx-data-memory"),
    dcc_store(id="dflx-testdataX-memory"),
    dcc_store(id="dflx-testdatay-memory"),
    dcc_store(id="dflx-inlabels-memory"),
    dcc_store(id="dflx-outlabels-memory"),
    render_all()
])
  
  
callback!(
    app,
    Output("dflx-data-memory", "data"),
    Output("dflx-output-data-upload", "children"),
    Output("dflx-output-plot", "children"),
    Output("dflx-nn-tab", "disabled"),
    Output("dflx-input-name-list", "children"),
    Output("dflx-output-name-list", "children"),
    Input("dflx-upload-data", "contents"),
    State("dflx-upload-data", "filename"),
) do contents, filename
    if (contents isa Nothing)
        throw(PreventUpdate())
    else
        df = parse_contents(contents, filename)
        return_data = render_table(df, filename; n_rows = 5)
        return_graph = render_graph_title(df)      
        row_names = names(df)  
        row_names = row_names[row_names .!= "id"]
        return (
            df, return_data,
            return_graph, false,
            render_mult_graphtitle(row_names, id_val="dflx-nninput-dropdown"), 
            render_mult_graphtitle(row_names, id_val="dflx-nnoutput-dropdown")
        )
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
callback!(app,
    Output("dflx-nn-layer-count", "data"),
    Output("dflx-hidden-layers", "children"), 
    Input("dflx-add-hidden-layer", "n_clicks"),
    Input("dflx-remove-hidden-layer", "n_clicks"),
    State("dflx-nn-layer-count", "data")    
) do nclicks_plus, nclicks_minus, layer_count
    ctx = callback_context()
    if isempty(ctx.triggered)
        throw(PreventUpdate())
    end
    if layer_count isa Nothing
        layer_count = 0
    end
    if split(ctx.triggered[1].prop_id,".")[1] == "dflx-add-hidden-layer"
        layer_count += 1
    else
        layer_count -= 1
    end
    return layer_count, render_nn_layer(layer_count)
end

#start training
callback!(app,
    Output("dflx-training-updates", "children"),
    Output("dflx-testdataX-memory", "data"),
    Output("dflx-testdatay-memory", "data"),
    Output("dflx-inlabels-memory", "data"),
    Output("dflx-outlabels-memory", "data"),
    Input("dflx-nnlayer-submit", "n_clicks"),
    State("dflx-nninput-dropdown", "value"),
    State("dflx-nnoutput-dropdown", "value"),
    State("dflx-hidden-layers", "children"),
    State("dflx-data-memory", "data"),
    State("dflx-nntrain-percent", "value"),  
    State("dflx-nntrain-epoch", "value"),   
    prevent_initial_call=true) do nclicks, labels_in, labels_out, child, df, tr_len, ep
    if child isa Nothing
        throw(PreventUpdate())
    end 
    global in_labels
    global out_labels
    in_labels = labels_in
    out_labels = labels_out
    global X_test
    global y_test
    new_tp = DataFrame(;zip(Tuple(Symbol.(df.colindex.names)), Tuple(df.columns))...)  
    X_train, X_test, y_train, y_test = format_nn_data(new_tp, in_labels, out_labels; training_percent=tr_len) 
    hidden_outs = [ch.props.children[1].props.children[1].props.children[2].props.value for ch in child] 
    @async train_nn(X_train, y_train, in_labels, out_labels, hidden_outs, chn; training_percent = tr_len, ep = ep)
    return render_training(), X_test, y_test, in_labels, out_labels
end

callback!(app,
  Output("live-update-graph", "figure"),
  Output("interval-component", "disabled"),
  Output("dflx-pred-tab", "disabled"),
  Output("dflx-testing-section", "children"),
  Output("dflx-pred-tab", "children"),
  Input("interval-component", "n_intervals"),
  State("live-update-graph", "figure"),
  State("dflx-nntrain-epoch", "value"),
  prevent_initial_call=true) do n, stg,epval
    global m
    global X_test 
    global y_test
    st = false  
    if n >= epval
        st = true 
    end
    if isready(chn) && (n <= epval)    
        l,ep,m = take!(chn)
        if !(stg isa Nothing)      
            if !(stg[1][1].x isa Nothing)
                append!(stg[1][1].x, ep)
                append!(stg[1][1].y, l)
            end  
        else  
            stg = [[(x = [ep], y = [l])]]    
        end
    end
    if st
        test_render = render_testing(m, X_test,y_test)
        pred_render = render_prediction_componnets(in_labels)
    else
        test_render = dbc_progress(value=(ep/epval)*100)
        pred_render = html_div()
    end   
    return Dict(
      "data" => [
        Dict(
            "x" => stg[1][1].x,
            "y" =>stg[1][1].y,
            "mode" => "line",
        ),  
      ]
    ),st, !st, test_render, pred_render
end

callback!(app, 
    Output("pred_out", "children"),
    Input((index = ALL, type = "preddone"), "value")
) do in_values
    global m
    global out_labels
    if (in_values isa Vector) && !(nothing in in_values)
        prediction =  m(in_values)
        return [
            html_div([
                dcc_input(
                    id = (index = idx, type = "preddout"),
                    value = val,
                    disabled = true
                ) 
            ]) for (idx, val) in enumerate(prediction)]
    else
        return html_div("nothing")
    end 
end

run_server(app, "0.0.0.0", 8050, debug=true)