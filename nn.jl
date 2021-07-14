using CSV, DataFrames
using Flux
using Flux: Data.DataLoader
using PlotlyJS
using StatsBase
using Random
using Dates

load_data = CSV.read("kc_house_data.csv", DataFrame)
date_vals = map(x->DateTime(x[1:8],"yyyymmdd"), load_data[!,"date"])
load_data[!,"month"] = Dates.month.(date_vals)
load_data[!,"year"] = Dates.year.(date_vals)

n_row = nrow(load_data)
sort_data = load_data[shuffle(1:n_row)[:], :]

X = sort_data[:, filter(x -> !(x in ["price", "date", "zipcode", "id"]), names(sort_data))]
y = sort_data[:, filter(x -> (x in ["price"]), names(sort_data))]

X = Array(X)
y = Array(y)

dtx = fit(UnitRangeTransform, X, dims=1)
X = StatsBase.transform(dtx, X)

dty = fit(UnitRangeTransform, y, dims=1)
y = StatsBase.transform(dty, y)

test_len = Int(ceil(n_row*.33))
X_train = X[1:n_row-test_len,:]'
X_test = X[n_row-test_len+1:end,:]'
y_train = y[1:n_row-test_len,:]'
y_test = y[n_row-test_len+1:end,:]'


data =  DataLoader((X_train,y_train), batchsize=128, shuffle=true)

m = Chain(
    Dense(19,19,Flux.relu), 
    Dense(19,19,Flux.relu),
    Dense(19,19,Flux.relu),
    Dense(19,19,Flux.relu),
    Dense(19,1)
)

L(x, y) = Flux.Losses.mse(m(x), y)

opt = ADAM()

ps = Flux.params(m)

stfunc() = @show(L(X_train,y_train)) 

Flux.@epochs 100 Flux.train!(L, ps, data, opt, cb = () -> stfunc())

plt = PlotlyJS.scatter(
  Dict(
    "mode" => "markers", 
    "x"=> vec(m(X_test)),
    "y"=>vec(y_test),
    "type" => "scatter"
  )
)
plt1 = PlotlyJS.scatter(
  Dict(
    "mode" => "line", 
    "x"=> vec(y_test),
    "y"=>vec(y_test)
  )
)
PlotlyJS.Plot([plt, plt1])


