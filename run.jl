include("precompile_funcs.jl")

using FluxDash

using .PrecompileFuncs
PrecompileFuncs.precompile_nn_train()

app = FluxDash.make_app()

port = haskey(ENV, "PORT") ? parse(Int64, ENV["PORT"]) : 8050

FluxDash.Dash.run_server(app, "0.0.0.0", port)