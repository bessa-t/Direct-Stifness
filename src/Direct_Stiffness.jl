module DirectStiffness
using LinearAlgebra, SparseArrays, TOML, Printf

include("types/material_section.jl")
include("types/geometry.jl")
include("types/element.jl")

include("elements/truss.jl")
include("elements/bernoulli_beam.jl")
include("elements/frame.jl")

include("assemble.jl")
include("input.jl")
include("boundary.jl")
include("external_forces.jl")
include("solver.jl")
include("internal_forces.jl")
include("report.jl")

# Full analysis: reads the TOML, solves, and writes outputs/<input name>.txt
function run_analysis(input_path::AbstractString;
                      output_dir = joinpath(@__DIR__, "..", "outputs"))
    # relative paths are resolved from the project root, not from where Julia was started
    input_path = joinpath(@__DIR__, "..", input_path)
    (; s, u_pre, F, element_q) = load_model(input_path)

    K      = build_global_stiffness_matrix(s)
    u, R   = solve_system(K, F, u_pre)
    forces = element_internal_forces(s, u, element_q)

    mkpath(output_dir)
    report_path = joinpath(output_dir, splitext(basename(input_path))[1] * ".txt")
    write_report(report_path, s, F, u_pre, u, R, forces)
    return report_path
end
end

# `julia src/Direct_Stiffness.jl [input.toml]` runs the analysis (default: inputs/2d_truss.toml)
if abspath(PROGRAM_FILE) == @__FILE__
    input = isempty(ARGS) ? "inputs/2d_truss.toml" : ARGS[1]
    println("Report written to ", normpath(DirectStiffness.run_analysis(input)))
end
