function format_nn_data(df, in_labels, out_labels; training_percent=70)
  n_row = nrow(df)
  labels = vcat(in_labels, out_labels)
  labels = unique(labels)
  #filter data
  filter_df = df[:, filter(x -> (x in labels), names(df))]

  X = filter_df[:, filter(x -> (x in vcat(in_labels)), names(filter_df))]
  y = filter_df[:, filter(x -> (x in vcat(out_labels)), names(filter_df))]

  X = Float64.(Array(X))
  y = Float64.(Array(y))

  dtx = fit(UnitRangeTransform, Float64.(X), dims=1)
  X = StatsBase.transform(dtx, X)

  train_len = Int(ceil(n_row*(training_percent/100)))
  X_train = X[1:train_len,:]'
  X_test = X[train_len+1:end,:]'
  y_train = y[1:train_len,:]'
  y_test = y[train_len+1:end,:]'
  return X_train, X_test, y_train, y_test 
end
function create_nn(X_train, y_train, in_labels, out_labels, hidden_outs; training_percent = 70, ep = 1)
  data =  DataLoader((X_train,y_train), batchsize=128, shuffle=true)
  in_len = in_labels isa Vector ? length(in_labels) : 1
  out_len = out_labels isa Vector ? length(out_labels) : 1
  in_layer = Dense(in_len, hidden_outs[1])
  out_layer = Dense(hidden_outs[end], out_len)
  hidden_layers = [Dense(hidden_outs[i], hidden_outs[i+1]) for i in 1:(length(hidden_outs)-1)]
  m = Chain(
    in_layer,
    hidden_layers...,
    out_layer
  )
  L(x, y) = Flux.Losses.mse(m(x), y)

  opt = ADAM()

  ps = Flux.params(m)

  # stfunc() = @show(L(X_train,y_train)) 

  # Flux.@epochs ep Flux.train!(L, ps, data, opt, cb = () -> stfunc())
  training_loss = 0.0
      for i in 1:ep
        for d in data
          gs = Flux.gradient(ps) do
            training_loss =L(d...)
            return training_loss
          end			
          Flux.Optimise.update!(opt, ps, gs)		
        end		
        #print loss
        put!(chn, (training_loss, i, m))
        # println("Traing loss: ", training_loss," Epoch: ", i)
      end
  return 0
end
function test_nn(m,x,y)
  yₚ = m(x)
  @show size(yₚ)
  maerr = Flux.Losses.mae(yₚ, y) #mean absolute error
  mserr = Flux.Losses.mse(yₚ, y) #mean square error
  crenpy = Flux.Losses.crossentropy(yₚ, y) #cross entropy
  return yₚ, maerr, mserr, crenpy
end