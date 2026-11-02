const Truss2D = Element{GeomData2D, TrussSection}

function transformation_matrix(e::Truss2D)
    c, s = e.geometry.c, e.geometry.s
    return [ c  s  0  0
             0  0  c  s ]
end

function element_stiffness(e::Truss2D)
    c, s = e.geometry.c, e.geometry.s
    E,A,L = e.material.E, e.section.A, e.geometry.L
     return(E * A / L) * [
     c^2    c*s   -c^2   -c*s ;
     c*s    s^2   -c*s   -s^2 ;
    -c^2   -c*s    c^2    c*s ;
    -c*s   -s^2    c*s    s^2
]
end

const Truss3D = Element{GeomData3D, TrussSection}

function transformation_matrix(e::Truss3D)
    l,m,n = e.geometry.l, e.geometry.m, e.geometry.n
    return [ l m n 0 0 0
             0 0 0 l m n ]
end

function element_stiffness(e::Truss3D)
    l,m,n = e.geometry.l, e.geometry.m, e.geometry.n
    E,A,L = e.material.E, e.section.A, e.geometry.L
     return (E * A / L) * [
     l^2    l*m    l*n   -l^2   -l*m   -l*n ;
     l*m    m^2    m*n   -l*m   -m^2   -m*n ;
     l*n    m*n    n^2   -l*n   -m*n   -n^2 ;
    -l^2   -l*m   -l*n    l^2    l*m    l*n ;
    -l*m   -m^2   -m*n    l*m    m^2    m*n ;
    -l*n   -m*n   -n^2    l*n    m*n    n^2
]
end

