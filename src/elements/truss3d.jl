struct Truss3D <: AbstractElement
    node_i::Int
    node_j::Int
    geom::GeomData3D
    E::Float64
    A::Float64
end

function transformation_matrix(e::Truss3D)
    l,m,n = e.geom.l, e.geom.m, e.geo.n
    return [ l m n 0 0 0
             0 0 0 l m n ]
end

function element_stiffness(e::Truss3D)
    l,m,n = e.geom.l, e.geom.m, e.geo.n
    E,A,L = e.E, e.A, e,geom.l
     return (E * A / L) * [
     l^2    l*m    l*n   -l^2   -l*m   -l*n ;
     l*m    m^2    m*n   -l*m   -m^2   -m*n ;
     l*n    m*n    n^2   -l*n   -m*n   -n^2 ;
    -l^2   -l*m   -l*n    l^2    l*m    l*n ;
    -l*m   -m^2   -m*n    l*m    m^2    m*n ;
    -l*n   -m*n   -n^2    l*n    m*n    n^2
]
end
