using CSV, DataFrames
using FluxDash
using FluxDash.Flux
using Random

df = CSV.read("$(@__DIR__)/../datasets/real_estate.csv", DataFrame)

n_row = nrow(df)
df = df[shuffle(1:n_row)[:], :] #shuffle data

labels = names(df)
in_labels = labels[end]
out_labels = labels[end]

X_train, X_test, y_train, y_test = FluxDash.format_nn_data(
    df, in_labels, out_labels; training_percent=75
) 

chn = Base.Channel{Tuple{Float64, Int, Chain}}(Inf)

hidden_outs = [2]
hidden_activations =["relu"]
FluxDash.train_nn(
    X_train, y_train, in_labels, out_labels, hidden_outs,
    chn, hidden_activations; training_percent = 75,
    epoc = 4, opt = "adam", eta = 0.1
)

app = FluxDash.make_app()

port = haskey(ENV, "PORT") ? parse(Int64, ENV["PORT"]) : 8050

t = @async FluxDash.Dash.run_server(app, "0.0.0.0", port)
sleep(120.0)