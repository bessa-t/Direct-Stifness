const Frame_2D = Element{GeomData2D, Frame_2D_Section}

function transformation_matrix(e::Frame_2D)
    c, s = e.geometry.c, e.geometry.s
    return [ c  s  0  0  0  0
            -s  c  0  0  0  0
             0  0  1  0  0  0
             0  0  0  c  s  0
             0  0  0  -s c  0
             0  0  0  0  0  1]
end

function element_stiffness(e::Frame_2D)
    E,A,L,I = e.material.E, e.section.A, e.geometry.L, e.section.Iz
    T = transformation_matrix(e)
    Ke = [
     E*A/L          0               0         -E*A/L          0               0
       0       12*E*I/L^3      6*E*I/L^2         0      -12*E*I/L^3      6*E*I/L^2
       0        6*E*I/L^2      4*E*I/L           0       -6*E*I/L^2      2*E*I/L
    -E*A/L          0               0          E*A/L          0               0
       0      -12*E*I/L^3     -6*E*I/L^2         0       12*E*I/L^3     -6*E*I/L^2
       0        6*E*I/L^2      2*E*I/L           0       -6*E*I/L^2      4*E*I/L
    ]
    return  T'*Ke* T
end