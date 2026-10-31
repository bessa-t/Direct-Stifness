using LinearAlgebra

abstract type element end

function stiffness_global(e::element)
    KL = stiffness_local(e)
    T = rotation_matrix(e)
    return  T' * KL * T 
end

struct GeomData2D
    c::Float64 
    s::Float64  
    L::Float64  
end

struct GeomData3D
    l::Float64 
    m::Float64  
    n::Float64  
    L::Float64  
end

function lengths_directions(mesh::Dict)
    elements = mesh["elements"]
    nodes = mesh["nodes"]
    n_elem = length(elements)
    dim = length(nodes[1])

    if dim == 2
        geom_data = Vector{GeomData2D}(undef, n_elem)

        for (i, elem) in enumerate(elements)
            id_i = Int(elem[1])
            id_j = Int(elem[2])

            dx = Float64(nodes[id_j][1] - nodes[id_i][1])
            dy = Float64(nodes[id_j][2] - nodes[id_i][2])
            L = hypot(dx, dy)

            geom_data[i] = GeomData2D(dx / L, dy / L, L)
        end

        return geom_data

    elseif dim == 3
        geom_data = Vector{GeomData3D}(undef, n_elem)

        for (i, elem) in enumerate(elements)
            id_i = Int(elem[1])
            id_j = Int(elem[2])

            dx = Float64(nodes[id_j][1] - nodes[id_i][1])
            dy = Float64(nodes[id_j][2] - nodes[id_i][2])
            dz = Float64(nodes[id_j][3] - nodes[id_i][3])

            L = hypot(dx, dy, dz)

            geom_data[i] = GeomData3D(dx / L, dy / L, dz / L, L)
        end

        return geom_data
    else
        error("Dimension not supported, please verify!")
    end
end