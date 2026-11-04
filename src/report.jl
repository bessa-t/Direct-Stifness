direction_header(::GeomData2D) = "angle [deg]"
direction_header(::GeomData3D) = "l, m, n"
direction_str(g::GeomData2D) = @sprintf("%11.3f", rad2deg(atan(g.s, g.c)))
direction_str(g::GeomData3D) = @sprintf("%.3f, %.3f, %.3f", g.l, g.m, g.n)

section_title(io::IO, title) = println(io, "\n", title, "\n", "-"^length(title))

# Plain-text report. u_pre: prescribed displacements (NaN = free), u: full solution,
# R = K*u - F (support reactions are the entries at the prescribed DOFs).
function write_report(io::IO, s::Structure, F, u_pre, u, R)
    d = s.dofs_per_node
    prescribed = findall(!isnan, u_pre)
    free = findall(isnan, u_pre)

    println(io, "DIRECT STIFFNESS METHOD - REPORT")
    println(io, "=" ^ 32)
    println(io, "(values in the units of the input file)")

    section_title(io, "1. Model")
    println(io, "Structure type : ", s.kind)
    println(io, "Nodes          : ", s.nnodes)
    println(io, "Elements       : ", length(s.elements))
    println(io, "DOFs per node  : ", d)
    println(io, "DOFs total     : ", length(u), " (", length(free), " free, ",
            length(prescribed), " prescribed)")

    section_title(io, "2. Elements")
    println(io, @sprintf("%4s %5s %5s %12s %12s %12s  %s", "elem", "i", "j", "L", "E", "A",
                         isempty(s.elements) ? "" : direction_header(s.elements[1].geometry)))
    for (k, e) in enumerate(s.elements)
        i, j = e.geometry.nodes
        println(io, @sprintf("%4d %5d %5d %12.4f %12.4e %12.4f  %s", k, i, j,
                             e.geometry.L, e.material.E, e.section.A,
                             direction_str(e.geometry)))
    end

    section_title(io, "3. Applied loads")
    loaded = findall(!iszero, F)
    isempty(loaded) && println(io, "(none)")
    for g in loaded
        println(io, @sprintf("%-8s %14.4f", "F" * dof_name(s, g)[2:end], F[g]))
    end

    section_title(io, "4. Prescribed displacements")
    for g in prescribed
        println(io, @sprintf("%-8s %14.6f", dof_name(s, g), u_pre[g]))
    end

    section_title(io, "5. Nodal displacements")
    println(io, @sprintf("%-8s %16s", "DOF", "value"))
    for g in eachindex(u)
        println(io, @sprintf("%-8s %16.6e", dof_name(s, g), u[g]))
    end

    section_title(io, "6. Support reactions")
    println(io, @sprintf("%-8s %16s", "DOF", "value"))
    for g in prescribed
        println(io, @sprintf("%-8s %16.4f", "R" * dof_name(s, g)[2:end], R[g]))
    end
end

function write_report(path::AbstractString, args...)
    open(io -> write_report(io, args...), path, "w")
    return path
end
