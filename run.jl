using FluxDash
app = FluxDash.make_app()

port = haskey(ENV, "PORT") ? parse(Int64, ENV["PORT"]) : 8050

t = @async FluxDash.Dash.run_server(app, "0.0.0.0", port)
sleep(120.0)