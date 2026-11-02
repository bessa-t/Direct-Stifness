function build_displacement_vector(s::Structure, boundary)
    d = s.dofs_per_node
    u_vec = fill(NaN, d * s.nnodes)

    for row in boundary
        node = Int(row[1])
        values = row[2:end]

        1 <= node <= s.nnodes ||
            error("boundary: node $node does not exist (model has $(s.nnodes) nodes)")
        length(values) == d ||
            error("boundary: node $node has $(length(values)) values, expected $d")

        u_vec[node_dofs(node, d)] .= values
    end

    any(!isnan, u_vec) || error("boundary: no supports defined")
    return u_vec
end
