@doc """
    InitialValueProblem(rhs, u0, tspan) -> InitialValueProblem
    IVP(args...; kwargs...) -> InitialValueProblem

returns a constructor for an `InitialValueProblem` with
- `rhs` : right-hand side derivative.
- `u0` : initial condition.
- `tspan` : time domain.
"""
mutable struct InitialValueProblem{rhs_T, u0_T, tspan_T} <: NSDEProblem
    rhs::rhs_T
    u0::u0_T
    tspan::tspan_T
end

InitialValueProblem(rhs::RightHandSideFunction, u0::Number, tspan) = InitialValueProblem(rhs, [u0], tspan)
InitialValueProblem(f::Function, u0, tspan) = InitialValueProblem(RHS(f), u0, tspan)
InitialValueProblem(rhs::RightHandSideFunction, u0, t0::Real, tN::Real) = InitialValueProblem(rhs, u0, (t0, tN))
InitialValueProblem(f::Function, u0, t0, tN) = InitialValueProblem(RHS(f), u0, t0, tN)
@doc (@doc InitialValueProblem) IVP(args...; kwargs...) = InitialValueProblem(args...; kwargs...)

function Base.copy(problem::InitialValueProblem)
    @↓ rhs, u0, tspan = problem
    return IVP(rhs, u0, tspan)
end
