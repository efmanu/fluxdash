# create_sysimage(
#            [:CSV, :DataFrames, :FluxDash, :Flux, :Random],
#                sysimage_path="sysnew_fluxdash.so",
#                    precompile_execution_file="FluxDash\\test\\nn_train.jl"
#                    )
run(`julia --sysimage sysnew_fluxdash.so --project run.jl`)