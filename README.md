# Flux Dash App

This an app with user interface to create, train and test a deep neural network.


## Run Locally

```julia
julia> using Pkg
julia> Pkg.activate(".")
julia> include("run.jl")
```

## App Configuration and setup

![Animation3](https://user-images.githubusercontent.com/22251968/133020240-d34dcd9f-4019-42f5-96fb-235100ef8e41.gif)


## Deploy in herokuapp

```
git push heroku master
```
Sometimes it won't push anything. Then do force pushing like below:
```
git push heroku master:master -f
```
