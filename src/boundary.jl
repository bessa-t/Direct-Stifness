# supports: pairs (node, values) from parse_nodal_rows
function build_displacement_vector(s::Structure, supports)
    d = s.dofs_per_node
    u_vec = fill(NaN, d * nnodes(s))

    for (node, values) in supports
        u_vec[node_dofs(node, d)] .= values
    end

    any(!isnan, u_vec) || error("boundary: no supports defined")
    return u_vec
end
