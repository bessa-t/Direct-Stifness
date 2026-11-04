const Beam = Element{GeomData2D, Beam_Section}


function element_stiffness(e::Beam)
    E,L,I = e.material.E, e.geometry.L, e.section.Iz
    # This matrix has no rotation: it only holds for horizontal bars with node i on the left
    e.geometry.c ≈ 1 || error("Beam between nodes $(e.geometry.nodes) is not horizontal with node i on the left")

    return (E * I / L^3) * [
     12     6*L   -12     6*L
    6*L   4*L^2  -6*L   2*L^2
    -12    -6*L    12    -6*L
    6*L   2*L^2  -6*L   4*L^2
]
end