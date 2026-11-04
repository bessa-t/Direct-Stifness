# Single entry point for the input file: only this file knows the TOML keys and row layouts.
# Everything downstream receives named, validated data.

const SECTION_PARSERS = Dict(
    "2d_truss" => d -> TrussSection(d["A"]),
    "3d_truss" => d -> TrussSection(d["A"]),
    "2d_beam"  => d -> Beam_Section(d["Iz"]),
    "2d_frame" => d -> Frame_2D_Section(d["A"], d["Iz"]),
    "3d_frame" => d -> Frame_3D(d["A"], d["Ix"], d["Iy"], d["Iz"],
                                d["Jx"], d["Jy"], d["Jz"]),
)

function load_model(path::AbstractString)
    data  = TOML.parsefile(path)
    s     = build_structure(data)
    loads = get(data, "loads", Dict())

    u_pre = build_displacement_vector(s, parse_nodal_rows(data["mesh"]["boundary"], s, "boundary"))
    constant_loads = parse_constant_loads(get(loads, "constant_loads", []), s)
    f_vec, f_dist  = build_F_vector(s, parse_nodal_rows(get(loads, "nodal_loads", []), s, "nodal_loads"),
                                    constant_loads)

    # The solver and the reactions (R = K*u - F) use the total load
    F = f_vec .+ f_dist

    # Uniform load of each element, needed for the internal forces
    element_q = zeros(length(s.elements))
    for (e, q) in constant_loads
        element_q[e] += q
    end

    return (; s, u_pre, F, f_vec, f_dist, element_q)
end

function build_structure(data)
    kind = data["structure"]
    haskey(SECTION_PARSERS, kind) ||
        error("Unknown structure \"$kind\". Options: $(join(keys(SECTION_PARSERS), ", "))")

    mesh  = data["mesh"]
    nodes = parse_nodes(mesh["nodes"])
    conn  = parse_connectivity(mesh["elements"], length(nodes))

    parse_section = SECTION_PARSERS[kind]
    materials = Dict(k => Material(v["E"], v["v"]) for (k, v) in data["materials"])
    sections  = Dict(k => parse_section(v)         for (k, v) in data["sections"])
    mats, secs = assign_properties(mesh, length(conn), materials, sections)

    elements = [Element(element_geometry(i, j, nodes), mats[k], secs[k])
                for (k, (i, j)) in enumerate(conn)]

    return Structure(kind, DOFS_PER_NODE[kind], nodes, elements)
end

parse_nodes(rows) = [Float64.(row) for row in rows]

# Rows [i, j] -> (i, j). The element number k is the position of the row.
function parse_connectivity(rows, n_nodes)
    conn = Tuple{Int,Int}[]
    for (k, row) in enumerate(rows)
        length(row) == 2 ||
            error("elements: element $k has $(length(row)) nodes, expected 2")
        i, j = Int(row[1]), Int(row[2])
        (1 <= i <= n_nodes && 1 <= j <= n_nodes) ||
            error("elements: element $k uses nodes ($i, $j), but the model has $n_nodes nodes")
        push!(conn, (i, j))
    end
    return conn
end

# Material and section of each element: the defaults, overridden by groups in file order.
function assign_properties(mesh, n_elements, materials, sections)
    mats = fill(materials[mesh["default_material"]], n_elements)
    secs = fill(sections[mesh["default_section"]], n_elements)

    for g in get(mesh, "groups", [])
        for k in g["elements"]
            1 <= k <= n_elements ||
                error("groups: element $k does not exist (model has $n_elements elements)")
            haskey(g, "material") && (mats[k] = materials[g["material"]])
            haskey(g, "section")  && (secs[k] = sections[g["section"]])
        end
    end

    return mats, secs
end

# Rows [node, v1, ..., vd] (supports and nodal loads) -> pairs (node, values).
function parse_nodal_rows(rows, s::Structure, label)
    d = s.dofs_per_node
    parsed = Tuple{Int,Vector{Float64}}[]

    for row in rows
        node   = Int(row[1])
        values = Float64.(row[2:end])

        1 <= node <= nnodes(s) ||
            error("$label: node $node does not exist (model has $(nnodes(s)) nodes)")
        length(values) == d ||
            error("$label: node $node has $(length(values)) values, expected $d")

        push!(parsed, (node, values))
    end

    return parsed
end

# Rows [element, q] -> pairs (element, q). The equivalent loads assume uy and θ are the last two
# DOFs of each node and that local y = global y, so only horizontal bars (i to the left of j) qualify.
function parse_constant_loads(rows, s::Structure)
    parsed = Tuple{Int,Float64}[]

    for row in rows
        length(row) == 2 ||
            error("constant_loads: row $row has $(length(row)) values, expected 2 (element, q)")
        e, q = Int(row[1]), Float64(row[2])

        s.kind in ("2d_beam", "2d_frame") ||
            error("constant_loads: not supported for structure \"$(s.kind)\"")
        1 <= e <= length(s.elements) ||
            error("constant_loads: element $e does not exist (model has $(length(s.elements)) elements)")
        s.elements[e].geometry.c ≈ 1 ||
            error("constant_loads: element $e is not horizontal with node i on the left")

        push!(parsed, (e, q))
    end

    return parsed
end
