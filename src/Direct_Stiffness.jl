module DirectStiffness
using LinearAlgebra, SparseArrays, TOML, Printf

include("types/material_section.jl")
include("types/geometry.jl")
include("types/element.jl")

include("elements/truss.jl")

include("assemble.jl")
include("boundary.jl")
include("types/external_forces.jl")
include("solver.jl")
include("report.jl")

# Full analysis: reads the TOML, solves, and writes outputs/<input name>.txt
function run_analysis(input_path::AbstractString;
                      output_dir = joinpath(@__DIR__, "..", "outputs"))
    # relative paths are resolved from the project root, not from where Julia was started
    input_path = joinpath(@__DIR__, "..", input_path)
    data  = read_model(input_path)
    s     = build_structure(data)
    K     = build_global_stiffness_matrix(s)
    u_pre = build_displacement_vector(s, data["mesh"]["boundary"])
    F     = build_F_vector(s, get(data, "loads", Dict()))

    u, R = solve_system(K, F, u_pre)

    mkpath(output_dir)
    report_path = joinpath(output_dir, splitext(basename(input_path))[1] * ".txt")
    write_report(report_path, s, F, u_pre, u, R)
    return report_path
end
end

# `julia src/Direct_Stiffness.jl [input.toml]` runs the analysis (default: inputs/truss.toml)
if abspath(PROGRAM_FILE) == @__FILE__
    input = isempty(ARGS) ? "inputs/truss.toml" : ARGS[1]
    println("Report written to ", normpath(DirectStiffness.run_analysis(input)))
end
