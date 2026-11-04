include("Direct_Stiffness.jl")
using .DirectStiffness

data  = DirectStiffness.read_model(joinpath(@__DIR__, "..", "inputs", "truss.toml"))
s     = DirectStiffness.build_structure(data)
K     = DirectStiffness.build_global_stiffness_matrix(s)
u_pre = DirectStiffness.build_displacement_vector(s, data["mesh"]["boundary"])
F     = DirectStiffness.build_F_vector(s, get(data, "loads", Dict()))

u, R = DirectStiffness.solve_system(K, F, u_pre)

DirectStiffness.write_report(stdout, s, F, u_pre, u, R)
