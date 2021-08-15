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
function generate_optmizer(opt, eta)
  if opt == "descent"
    return Flux.Optimise.Descent(eta)
  elseif opt == "momentum"
    return Flux.Optimise.Momentum(eta)
  elseif opt == "nesterov"
    return Flux.Optimise.Nesterov(eta)
  elseif opt == "rmsprop"
    return Flux.Optimise.RMSProp(eta)
  elseif opt == "adam"
    return Flux.Optimise.ADAM(eta)
  elseif opt == "radam"
    return Flux.Optimise.RADAM(eta)
  elseif opt == "adamax"
    return Flux.Optimise.AdaMax(eta)
  else
    return Flux.Optimise.ADAM(eta)
  end
end
function generate_dense(in,out, act_fn)
  if act_fn == "no"
    return Dense(in,out)
  elseif act_fn == "relu"
    return Dense(in,out, Flux.relu)
  elseif act_fn == "sigmoid"
    return Dense(in,out, Flux.σ)
  elseif act_fn == "softmax"
    return Dense(in,out, Flux.softmax)
  elseif act_fn == "tanh"
    return Dense(in,out, Flux.tanh)
  elseif act_fn == "rrelu"
    return Dense(in,out, Flux.rrelu)
  elseif act_fn == "celu"
    return Dense(in,out, Flux.celu)
  elseif act_fn == "elu"
    return Dense(in,out, Flux.σ)
  elseif act_fn == "gelu"
    return Dense(in,out, Flux.gelu)
  else
    return Dense(in,out)
  end
end
function train_nn(X_train, y_train, in_labels, out_labels, 
  hidden_outs, chn, hidden_activations; training_percent = 70,
  ep = 1, opt = "adam", eta = 0.1)
  data =  DataLoader((X_train,y_train), batchsize=128, shuffle=true)
  in_len = in_labels isa Vector ? length(in_labels) : 1
  out_len = out_labels isa Vector ? length(out_labels) : 1
  in_layer = Dense(in_len, hidden_outs[1])
  out_layer = Dense(hidden_outs[end], out_len)
  # hidden_layers = [Dense(hidden_outs[i], hidden_outs[i+1]) for i in 1:(length(hidden_outs)-1)]
  hidden_layers = []
  for i in 1:(length(hidden_outs)-1)
    push!(hidden_layers, generate_dense(
        hidden_outs[i], hidden_outs[i+1],
        hidden_activations[i]
      ) 
    )
  end
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
        put!(chn, (training_loss, i, m))
        # println("Traing loss: ", training_loss," Epoch: ", i)
      end
  return 0
end
function test_nn(trained_model,x,y)
  yₚ = trained_model(x)
  maerr = Flux.Losses.mae(yₚ, y) #mean absolute error
  mserr = Flux.Losses.mse(yₚ, y) #mean square error
  crenpy = Flux.Losses.crossentropy(yₚ, y) #cross entropy
  
  return yₚ, maerr, mserr, crenpy
end