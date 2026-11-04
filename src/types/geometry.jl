abstract type AbstractGeom end

struct GeomData2D <: AbstractGeom
    nodes::Tuple{Int,Int}
    c::Float64 
    s::Float64  
    L::Float64  
end

struct GeomData3D <: AbstractGeom
    nodes::Tuple{Int,Int}
    l::Float64 
    m::Float64  
    n::Float64  
    L::Float64  
end

function element_geometry(i::Int, j::Int, nodes::AbstractVector)
    d = nodes[j] .- nodes[i]
    L = norm(d)
    L > 0 || error("Element between nodes $i and $j has zero length")

    return geometry_data((i, j), d ./ L, L)
end

geometry_data(nodes, dir, L) =
    length(dir) == 2 ? GeomData2D(nodes, dir[1], dir[2], L) :
    length(dir) == 3 ? GeomData3D(nodes, dir[1], dir[2], dir[3], L) :
    error("Dimension not supported, please verify!")
