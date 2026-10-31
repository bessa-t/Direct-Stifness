include("../types.jl")

struct Truss2D <: AbstractElement
    node_i::Int
    node_j::Int
    geom::GeomData2D
    E::Float64
    A::Float64
end

function transformation_matrix(e::Truss2D)
    c, s = e.geom.c, e.geom.s
    return [ c  s  0  0
             0  0  c  s ]
end

function element_stiffness(e::Truss3D)
    c, s = e.geom.c, e.geom.s
    E,A,L = e.E, e.A, e,geom.l
     return(E * A / L) * [
     c^2    c*s   -c^2   -c*s ;
     c*s    s^2   -c*s   -s^2 ;
    -c^2   -c*s    c^2    c*s ;
    -c*s   -s^2    c*s    s^2
]
end