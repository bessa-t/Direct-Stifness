include("Direct_Stiffness.jl")
using .DirectStiffness

data = DirectStiffness.read_model(joinpath(@__DIR__, "..", "inputs", "truss.toml"))
s = DirectStiffness.build_structure(data)
K = DirectStiffness.build_global_stiffness_matrix(s)
display(typeof(s))
display(Matrix(K))
