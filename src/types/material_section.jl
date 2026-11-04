struct Material 
    E::Float64
    v::Float64
end


function G(E,v)
    return E/(2*(1+v))
end

abstract type AbstractSection end

struct TrussSection <: AbstractSection
    A::Float64
end

struct Beam_Section <: AbstractSection
    Iz::Float64
end

struct Frame_2D_Section <: AbstractSection
    A::Float64
    Iz::Float64
end

struct Frame_3D <: AbstractSection
    A::Float64
    Ix::Float64
    Iy::Float64
    Iz::Float64
    Jx::Float64
    Jy::Float64
    Jz::Float64
end
