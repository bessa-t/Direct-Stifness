include("Direct_Stiffness.jl")
using .DirectStiffness

(; s, u_pre, F, element_q) = DirectStiffness.load_model(joinpath(@__DIR__, "..", "inputs", "2d_truss.toml"))

K      = DirectStiffness.build_global_stiffness_matrix(s)
u, R   = DirectStiffness.solve_system(K, F, u_pre)
forces = DirectStiffness.element_internal_forces(s, u, element_q)

DirectStiffness.write_report(stdout, s, F, u_pre, u, R, forces)
