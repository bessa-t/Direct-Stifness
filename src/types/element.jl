abstract type AbstractElement end

struct Element{G<:AbstractGeom, S<:AbstractSection} <: AbstractElement
    geometry :: G
    material :: Material
    section  :: S
end

function local_vectors(e::AbstractElement, v::AbstractVector)
    T = transformation_matrix(e)
    return  T * v
end
   
struct ElementStiffness
    nodes::Tuple{Int,Int}
    dofs_per_node::Int
    K::Matrix{Float64}
end
     
