@doc """
    RightHandSideFunction(f, f!, Df, Df!) <: InitialValueParameters
    RightHandSideFunction(f_or_f!::Function) <: InitialValueParameters
    RHS(args...; kwargs...) <: InitialValueParameters

returns a constructor for the right-hand side of an `InitialValueProblem`.

# Arguments
- `f   :: Function` : right-hand side derivative.
- `f!  :: Function` : right-hand side derivative (in-place).
- `Df  :: Function` : jacobian of right-hand side derivative.
- `Df! :: Function` : jacobian of right-hand side derivative (in-place).
"""
struct RightHandSideFunction{f_T, f!_T, Df_T, Df!_T} <: InitialValueParameters
    f::f_T
    f!::f!_T
    Df::Df_T
    Df!::Df!_T
end

function RightHandSideFunction(f_or_f!::Function)
    # Check if f_or_f! has form f(u, t)
    if hasmethod(f_or_f!, NTuple{2, Any})
        f = f_or_f!
        f! = (du, u, t) -> du .= f_or_f!(u, t)
        Df = (u, t) -> ForwardDiff.jacobian(u -> f_or_f!(u, t), u)
        Df! = (J, du, u, t) -> ForwardDiff.jacobian!(J, u -> f_or_f!(u, t), u)
        return RightHandSideFunction(f, f!, Df, Df!)
    # Check if f_or_f! has form f!(du, u, t)
    elseif hasmethod(f_or_f!, NTuple{3, Any})
        f! = f_or_f!
        f = (u, t) -> f_or_f!(similar(u), u, t)
        Df = (u, t) -> ForwardDiff.jacobian((du, u) -> f_or_f!(du, u, t), similar(u), u)
        Df! = (J, du, u, t) -> ForwardDiff.jacobian!(J, (du, u) -> f_or_f!(du, u, t), du, u)
        return RightHandSideFunction(f, f!, Df, Df!)
    end
end
@doc (@doc RightHandSideFunction) RHS(args...; kwargs...) = RightHandSideFunction(args...; kwargs...)
