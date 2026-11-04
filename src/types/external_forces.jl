# nodal_loads: pairs (node, values) from parse_nodal_rows
# constant_loads: pairs (element, q) from parse_constant_loads
# Returns (f_vec, f_dist): loads applied at the nodes and nodal equivalents of the distributed loads.
function build_F_vector(s::Structure, nodal_loads, constant_loads)
    d = s.dofs_per_node
    n = nnodes(s)
    f_vec = zeros(d *n)
    f_dist = zeros(d * n)

    for (node, values) in nodal_loads
        f_vec[node_dofs(node, d)] .+= values
    end

    # Equivalent nodal loads of a uniform q: [qL/2, qL²/12, qL/2, -qL²/12] on (uy_i, θ_i, uy_j, θ_j)
    for (e, q) in constant_loads
        element = s.elements[e]
        L = element.geometry.L
        c = q*L/12
        e_dofs = element_dofs(element,d)
        half = length(e_dofs) ÷ 2
        i,j = e_dofs[1:half][end-1:end]
        k,l = e_dofs[half+1:end][end-1:end]
        f_dist[i] += c * 6
        f_dist[j] += c * L
        f_dist[k] += c * 6
        f_dist[l] -= c * L
    end

    # Trapezoidal loads: not wired in yet (trapezoidal_loads is neither an argument nor read from the TOML)
    # for (e, q1,q2) in trapezoidal_loads
    #     element = s.elements[e]
    #     L = element.geometry.L
    #
    #     e_dofs = element_dofs(element,d)
    #     half = length(e_dofs) ÷ 2
    #
    #     i,j = e_dofs[1:half][end-1:end]
    #     k,l = e_dofs[half+1:end][end-1:end]
    #
    #     f_dist[i] += (7*q1*L)/20 + (3*q2*L)/20
    #     f_dist[j] += (q1*L^2)/20 + (q2*L^2)/30
    #     f_dist[k] += (3*q1*L)/20 + (7*q2*L)/20
    #     f_dist[l] -= (q1*L^2)/30 + (q2*L^2)/20
    # end

    return (f_vec, f_dist)
end

