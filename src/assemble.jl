const DOFS_PER_NODE = Dict("2d_truss" => 2, "3d_truss" => 3, "2d_beam" => 2,
                           "2d_frame" => 3, "3d_frame" => 6)

const DOF_NAMES = Dict(
    "2d_truss" => ("x", "y"),
    "3d_truss" => ("x", "y", "z"),
    "2d_beam"  => ("y", "θ"),
    "2d_frame" => ("x", "y", "θ"),
    "3d_frame" => ("x", "y", "z", "θx", "θy", "θz"),
)

# DOF numbering: node-major, e.g. 2D truss -> u1x, u1y, u2x, u2y, ...
# Node n owns positions (n-1)*d+1 : n*d, ordered (ux, uy[, uz][, rotations])
node_dofs(n, d) = (n-1)*d+1 : n*d

struct Structure{E<:Element}
    kind::String
    dofs_per_node::Int
    nodes::Vector{Vector{Float64}}    # coordinates; node k = nodes[k]
    elements::Vector{E}
end

nnodes(s::Structure) = length(s.nodes)

# Global DOF number -> label, e.g. 5 in a 2D truss -> "u3x"
function dof_name(s::Structure, g::Int)
    d = s.dofs_per_node
    node = (g-1) ÷ d + 1
    comp = (g-1) % d + 1
    return "u$(node)$(DOF_NAMES[s.kind][comp])"
end

function build_global_stiffness_matrix(s::Structure)
    d = s.dofs_per_node
    n = nnodes(s) * d

    rows = Int[]
    cols = Int[]
    vals = Float64[]

    for e in s.elements
        idx = element_dofs(e, d)
        Ke  = element_stiffness(e)

        for b in eachindex(idx), a in eachindex(idx)
            push!(rows, idx[a])
            push!(cols, idx[b])
            push!(vals, Ke[a, b])
        end
    end

    return sparse(rows, cols, vals, n, n)
end
