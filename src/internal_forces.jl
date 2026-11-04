get_internal_forces(t :Truss2D,u)
T = transformation_matrix(t)
return t.E * t.A /t.L * T *(u[1]-u[2])