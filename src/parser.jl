using TOML

data = TOML.parsefile("inputs/truss.toml")
println(data["mesh"]["nodes"])