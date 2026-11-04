abstract type AbstractElement end

struct Element{G<:AbstractGeom, S<:AbstractSection} <: AbstractElement
    geometry :: G
    material :: Material
    section  :: S
end

# Global DOFs of the element, ordered [DOFs of node i; DOFs of node j]. d = DOFs per node.
function element_dofs(e::Element, d)
    i, j = e.geometry.nodes
    return vcat(node_dofs(i, d), node_dofs(j, d))
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
     
