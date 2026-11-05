# Internal forces of each bar. Every method returns a NamedTuple, so the report can print any structure.
V(x, q, c1)     = q * x + c1
M(x, q, c1, c2) = q * x^2 / 2 + c1 * x + c2

# Integration constants from the end displacements (v1, θ1) and (v2, θ2)
function integration_constants(EI, L, q, v1, θ1, v2, θ2)
    A = [ 12*EI/L^3    6*EI/L^2   -12*EI/L^3    6*EI/L^2
          -6*EI/L^2   -4*EI/L       6*EI/L^2   -2*EI/L
           0           EI           0           0
           EI          0            0           0       ]

    return A * [v1, θ1, v2 - q*L^4/(24*EI), θ2 - q*L^3/(6*EI)]
end

function bending_forces(EI, L, q, v1, θ1, v2, θ2)
    c1, c2, c3, c4 = integration_constants(EI, L, q, v1, θ1, v2, θ2)
    return (Vi = V(0, q, c1), Vj = V(L, q, c1), Mi = M(0, q, c1, c2), Mj = M(L, q, c1, c2))
end


function get_internal_forces(t::Union{Truss2D,Truss3D}, u_e, q = (qa = 0.0, qt = 0.0))
    u_local = transformation_matrix(t) * u_e    
    return (N = t.material.E * t.section.A / t.geometry.L * (u_local[2] - u_local[1]),)
end

function get_internal_forces(e::Beam, u_e, q = (qa = 0.0, qt = 0.0))
    EI = e.material.E * e.section.Iz
    v1, θ1, v2, θ2 = u_e
    return bending_forces(EI, e.geometry.L, q.qt, v1, θ1, v2, θ2)
end

function get_internal_forces(e::Frame_2D, u_e, q = (qa = 0.0, qt = 0.0))
    u_local = transformation_matrix(e) * u_e    

    E, A, L = e.material.E, e.section.A, e.geometry.L
    EI = E * e.section.Iz
    N0 = E * A / L * (u_local[4] - u_local[1])      # mean axial force (tension positive)

    # An axial load qa makes N vary linearly: N(x) = Ni - qa*x, with mean N0
    return (Ni = N0 + q.qa * L / 2, Nj = N0 - q.qa * L / 2,
            bending_forces(EI, L, q.qt, u_local[2], u_local[3], u_local[5], u_local[6])...)
end

# element_q: uniform load of each element, from load_model
function element_internal_forces(s::Structure, u, element_q)
    d = s.dofs_per_node
    return [get_internal_forces(e, u[element_dofs(e, d)], q) for (e, q) in zip(s.elements, element_q)]
end
