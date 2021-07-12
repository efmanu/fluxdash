function create_nn(df, in_labels, out_labels, hidden_outs; training_percent = 70, ep = 1)
  labels = vcat(in_labels, out_labels)
  labels = unique(labels)
  #filter data
  filter_df = df[:, filter(x -> (x in labels), names(df))]

  #shuffle data
  n_row = nrow(filter_df)
  shuffle_data = filter_df[shuffle(1:n_row)[:], :]

  X = shuffle_data[:, filter(x -> (x in vcat(in_labels)), names(shuffle_data))]
  y = shuffle_data[:, filter(x -> (x in vcat(out_labels)), names(shuffle_data))]

  X = Float64.(Array(X))
  y = Float64.(Array(y))

  dtx = fit(UnitRangeTransform, Float64.(X), dims=1)
  X = StatsBase.transform(dtx, X)

  dty = fit(UnitRangeTransform, y, dims=1)
  y = StatsBase.transform(dty, y)

  train_len = Int(ceil(n_row*(training_percent/100)))
  X_train = X[1:train_len,:]'
  X_test = X[train_len+1:end,:]'
  y_train = y[1:train_len,:]'
  y_test = y[train_len+1:end,:]'

  data =  DataLoader((X_train,y_train), batchsize=128, shuffle=true)
  
  in_len = in_labels isa Vector ? length(in_labels) : 1
  out_len = out_labels isa Vector ? length(out_labels) : 1
  in_layer = Dense(in_len, hidden_outs[1])
  out_layer = Dense(hidden_outs[end], in_len)
  hidden_layers = [Dense(hidden_outs[i], hidden_outs[i+1]) for i in 1:(length(hidden_outs)-1)]
  m = Chain(
    in_layer,
    hidden_layers...,
    out_layer
  )
  L(x, y) = Flux.Losses.mse(m(x), y)

  opt = ADAM()

  ps = Flux.params(m)

  stfunc() = @show(L(X_train,y_train)) 

  Flux.@epochs ep Flux.train!(L, ps, data, opt, cb = () -> stfunc())
  return "success"
end