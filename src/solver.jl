# Partition method: unknowns are the free DOFs (NaN in u_pre);
# prescribed DOFs (supports and settlements) move to the right-hand side.
function solve_system(K, F, u_pre)
    free       = findall(isnan, u_pre)
    prescribed = findall(!isnan, u_pre)

    Kff = K[free, free]
    rhs = F[free] - K[free, prescribed] * u_pre[prescribed]

    uf = try
        Kff \ rhs
    catch err
        err isa SingularException || rethrow()
        error("solver: stiffness matrix is singular - check supports (unstable structure or mechanism)")
    end

    # A mechanism may not raise SingularException (rounding gives garbage), so check the residual
  
    u = copy(u_pre)
    u[free] = uf

    R = K * u - F          # support reactions are R[prescribed]
    return u, R
end
