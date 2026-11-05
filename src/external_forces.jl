function local_load(e::Element{GeomData2D}, qx, qy)
    c, s = e.geometry.c, e.geometry.s
    return (qa = c*qx + s*qy, qt = -s*qx + c*qy)
end

# Nodal equivalents of the uniform load, in global axes.
# Local vector (u, v, θ at i and j): [qa L/2, qt L/2, qt L²/12, qa L/2, qt L/2, -qt L²/12]
function equivalent_nodal_loads(e::Beam, qx, qy)
    L = e.geometry.L
    return [qy*L/2, qy*L^2/12, qy*L/2, -qy*L^2/12]
end

function equivalent_nodal_loads(e::Frame_2D, qx, qy)
    L = e.geometry.L
    qa, qt = local_load(e, qx, qy)
    f_local = [qa*L/2, qt*L/2, qt*L^2/12, qa*L/2, qt*L/2, -qt*L^2/12]
    return transformation_matrix(e)' * f_local          
end

# nodal_loads: pairs (node, values) from parse_nodal_rows
# constant_loads:  (element, qx, qy) from parse_constant_loads
# Returns (f_vec, f_dist): loads applied at the nodes and nodal equivalents of the distributed loads.
function build_F_vector(s::Structure, nodal_loads, constant_loads)
    d = s.dofs_per_node
    n = nnodes(s)
    f_vec = zeros(d *n)
    f_dist = zeros(d * n)

    for (node, values) in nodal_loads
        f_vec[node_dofs(node, d)] .+= values
    end

    # Nodal equivalents of a uniform load (global components qx, qy), already in global axes
    for (e, qx, qy) in constant_loads
        element = s.elements[e]
        f_dist[element_dofs(element, d)] .+= equivalent_nodal_loads(element, qx, qy)
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

