function build_F_vector(s::Structure, loads)

    d = s.dofs_per_node
    f_vec = zeros(d * s.nnodes)

    for row in get(loads, "nodal_loads", [])
        node = Int(row[1])
        values = row[2:end]

        1 <= node <= s.nnodes ||
            error("loads (nodal_loads): node $node does not exist (model has $(s.nnodes) nodes)")
        length(values) == d ||
            error("loads (nodal_loads): node $node has $(length(values)) values, expected $d")

        f_vec[node_dofs(node, d)] .+= values
    end
    for row in get(loads, "constant_loads", [])
    end
    return f_vec
end
