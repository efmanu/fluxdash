module FluxDash

#use packages
using CSV: Options
using Dash, DashBootstrapComponents, DashHtmlComponents, DashCoreComponents
using DashTable, DashDaq
using Core: Typeof
using Base64, Dates, CSV, DataFrames
using PlotlyJS
using Random, StatsBase
using Flux
using Flux: Data.DataLoader

#Initialize channel to get data during training
chn = Channel{Tuple{Float64, Int, Chain}}(Inf)
m = nothing #Initialized Chain
in_labels = nothing #Intialized label name vector corresponds to input data
out_labels = nothing #Intialized label name vector corresponds to output data
X_test = nothing #Intialized input test data
y_test = nothing #Intialized output test data
ep = 0
st = false 
x_graph = []
y_graph = []

include("utils.jl")
include("render_dhc.jl")
include("generate_nn.jl")

function make_app()
	#CDN for fonts
	external_stylesheets = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"

	global chn, m, in_labels, out_labels, X_test, y_test,ep, st, x_graph, y_graph
	#Initialize channel to get data during training
	chn = Channel{Tuple{Float64, Int, Chain}}(Inf)
	m = nothing #Initialized Chain
	in_labels = nothing #Intialized label name vector corresponds to input data
	out_labels = nothing #Intialized label name vector corresponds to output data
	X_test = nothing #Intialized input test data
	y_test = nothing #Intialized output test data
	ep = 0
	st = false 
	x_graph = []
	y_graph = []
	app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP,external_stylesheets], 
	    suppress_callback_exceptions=true)

	#setup dashboard
	app.layout = html_div([
	    dcc_store(id="dflx-data-memory"), #memory to store data
	    dcc_store(id="dflx-testdataX-memory"), #memory to store input labels
	    dcc_store(id="dflx-testdatay-memory"), #memory to store output labels
	    dcc_store(id="dflx-inlabels-memory"), #memory to store input test data
	    dcc_store(id="dflx-outlabels-memory"), #memory to store output test data
	    render_all() #To render all other components
	])

	#=
	This callback aims to upload data as CSV file and store data in memory.
	Moreover, this callback render interactive graph and table with loaded data 
	=#  
	callback!(
	    app,
	    Output("dflx-data-memory", "data"),
	    Output("dflx-output-data-upload", "children"),
	    Output("dflx-output-plot", "children"),
	    Output("dflx-nn-tab", "disabled"),
	    Output("dflx-input-name-list", "children"),
	    Output("dflx-output-name-list", "children"),
	    Input("dflx-upload-data", "contents"),
		Input("dflx-def-upload-data", "n_clicks"),
	    State("dflx-upload-data", "filename"),
		State("dflx-def-upload-data-drop", "value")	
	) do contents, sel_clicks, filename, drop_val
	
		ctx1 =callback_context() 
	    if !(ctx1 isa Nothing)			
			if !isempty(ctx1.triggered)
				if ctx1.triggered[1].prop_id == "dflx-upload-data.contents"
					
					df = parse_contents(contents, filename)
				elseif ctx1.triggered[1].prop_id == "dflx-def-upload-data.n_clicks"
					if drop_val == "1"
						df = CSV.read(download("https://raw.githubusercontent.com/efmanu/fluxdash/master/FluxDash/datasets/real_estate.csv"), DataFrame)
						df[!,"id"] = 1:nrow(df)
						filename = "Real_Estate.csv"
					elseif drop_val == "2"
						df = CSV.read(download("https://raw.githubusercontent.com/plotly/datasets/master/solar.csv"), DataFrame)
						df[!,"id"] = 1:nrow(df)
						filename = "Solar.csv"
					elseif drop_val == "3"
						df = CSV.read(download("https://raw.githubusercontent.com/efmanu/fluxdash/master/FluxDash/datasets/kc_house_data.csv"), DataFrame)
						df[!,"id"] = 1:nrow(df)
						filename = "House_Price.csv"
					else
						throw(PreventUpdate())					
					end						
				end
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
			else
				throw(PreventUpdate())
			end
		else
			throw(PreventUpdate())
	    end
	end

	#=
	This callback aims to render graph interactively based on selected labels
	=#
	callback!(app,
	    Output("dflx-plot-graph", "figure"),
	    Input("dflx-graph-dropdown-x", "value"),
	    Input("dflx-graph-dropdown-y", "value"),
	    State("dflx-data-memory", "data")    
	) do valuex, valuey, df
	    new_tp = DataFrame(;zip(Tuple(Symbol.(df.colindex.names)), Tuple(df.columns))...)
	    return  render_graph(new_tp, valuex, valuey)
	end

	#=
	This callback aims to render Neural network hideen layers
	=#
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

	#=
	This callback aims to start neural network training 
	Also this callback graph between number of  epoch vs loss
	=#
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
	    State("dflx-nntrain-optimizer","value"), 
	    State("dflx-nntrain-lrate","value"),
	    prevent_initial_call=true) do nclicks, labels_in, labels_out, child, df, tr_len, epval, opt, eta
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
	    hidden_activations = [ch.props.children[1].props.children[1].props.children[3].props.value for ch in child]  
		reset_vars()
	    train_nn(X_train, y_train, in_labels, out_labels, hidden_outs, chn, hidden_activations; training_percent = tr_len, epoc = epval, opt = opt, eta = eta)
	    return render_training(), X_test, y_test, in_labels, out_labels
	end
	
	#=
	This callback updates the loss vs epoch graph every 100 ms and stop updation if 
	training finished. Also renders test results, if training is finished
	=#
	callback!(app,
	  Output("live-update-graph", "figure"),
	  Output("interval-component", "disabled"),
	  Output("dflx-pred-tab", "disabled"),
	  Output("dflx-testing-section", "children"),
	  Output("dflx-pred-tab", "children"),
	  Input("interval-component", "n_intervals"),
	  State("live-update-graph", "figure"),
	  State("dflx-nntrain-epoch", "value"),
	  prevent_initial_call=true) do n, stg, epval
	    global m, ep, st
		global x_graph, y_graph
	    global X_test 
	    global y_test
	    if isready(chn)
	    	l,ep,m = take!(chn)
			if ep >= epval
				st = true
			end
			append!(x_graph, ep)
			append!(y_graph, l)
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
	            "x" => x_graph,
	            "y" => y_graph,
	            "mode" => "line",
	        ),  
	    ]
	    ), st, !st, test_render, pred_render 
	    
	end

	#=
	This callback render predcted output by inputing user data to trained model
	=#
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
	return app
end

end # module
