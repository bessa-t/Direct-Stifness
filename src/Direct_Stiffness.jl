module DirectStiffness
using LinearAlgebra, SparseArrays, TOML

include("types/material_section.jl")
include("types/geometry.jl")
include("types/element.jl")

include("elements/truss.jl")

include("assemble.jl")
include("boundary.jl")
include("types/external_forces.jl")
end
