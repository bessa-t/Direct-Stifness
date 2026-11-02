read_model(path::AbstractString) = TOML.parsefile(path)

const DOFS_PER_NODE = Dict("2d_truss" => 2, "3d_truss" => 3,
                           "2d_frame" => 3, "3d_frame" => 6)

const DOF_NAMES = Dict(
    "2d_truss" => ("x", "y"),
    "3d_truss" => ("x", "y", "z"),
    "2d_frame" => ("x", "y", "θ"),
    "3d_frame" => ("x", "y", "z", "θx", "θy", "θz"),
)

# DOF numbering: node-major, e.g. 2D truss -> u1x, u1y, u2x, u2y, ...
# Node n owns positions (n-1)*d+1 : n*d, ordered (ux, uy[, uz][, rotations])
node_dofs(n, d) = (n-1)*d+1 : n*d

struct Structure{E<:Element}
    kind::String
    dofs_per_node::Int
    nnodes::Int
    elements::Vector{E}
end


const SECTION_PARSERS = Dict(
    "2d_truss" => d -> TrussSection(d["A"]),
    "3d_truss" => d -> TrussSection(d["A"]),
    "2d_frame" => d -> Frame_2D(d["A"], d["Iz"]),
    "3d_frame" => d -> Frame_3D(d["A"], d["Ix"], d["Iy"], d["Iz"],
                                d["Jx"], d["Jy"], d["Jz"]),
)

function build_structure(data)
    mesh   = data["mesh"]
    nodes  = mesh["nodes"]
    conn   = mesh["elements"]
    groups = get(mesh, "groups", [])

    kind = data["structure"]
    haskey(SECTION_PARSERS, kind) ||
        error("Unknown structure \"$kind\". Options: $(join(keys(SECTION_PARSERS), ", "))")

    parse_section = SECTION_PARSERS[kind]
    materials = Dict(k => Material(v["E"], v["v"]) for (k, v) in data["materials"])
    sections  = Dict(k => parse_section(v)         for (k, v) in data["sections"])

    elements = [
        let p = element_material(k, mesh, groups, materials, sections)
            Element(element_geometry(conn[k], nodes), p.material, p.section)
        end
        for k in eachindex(conn)
    ]

    return Structure(kind, DOFS_PER_NODE[kind], length(nodes), elements)
end

# Global DOF number -> label, e.g. 5 in a 2D truss -> "u3x"
function dof_name(s::Structure, g::Int)
    d = s.dofs_per_node
    node = (g-1) ÷ d + 1
    comp = (g-1) % d + 1
    return "u$(node)$(DOF_NAMES[s.kind][comp])"
end

function build_global_stiffness_matrix(s::Structure)
    d = s.dofs_per_node
    n = s.nnodes * d

    rows = Int[]
    cols = Int[]
    vals = Float64[]

    for e in s.elements
        i, j = e.geometry.nodes
        idx = vcat(node_dofs(i, d), node_dofs(j, d))
        Ke  = element_stiffness(e)

        for b in eachindex(idx), a in eachindex(idx)
            push!(rows, idx[a])
            push!(cols, idx[b])
            push!(vals, Ke[a, b])
        end
    end

    return sparse(rows, cols, vals, n, n)
end
