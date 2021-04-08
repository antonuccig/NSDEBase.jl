@doc """
RightHandSideFunction(f, f!, Df, Df!) -> RightHandSideFunction
RightHandSideFunction(f_or_f!::Function) -> RightHandSideFunction
RHS(args...; kwargs...) -> RightHandSideFunction

returns a constructor for the right-hand side derivative of an `InitialValueProblem`.

# Arguments
- `f   :: Function` : right-hand side derivative.
- `f!  :: Function` : right-hand side derivative (in-place).
- `Df  :: Function` : jacobian of right-hand side derivative.
- `Df! :: Function` : jacobian of right-hand side derivative (in-place).
"""
struct RightHandSideFunction{f_T, f!_T, Df_T, Df!_T}
    f::f_T
    f!::f!_T
    Df::Df_T
    Df!::Df!_T
end

function RightHandSideFunction(f_or_f!::Function)
    if hasmethod(f_or_f!, NTuple{2, Any})
        f = f_or_f!
        f! = (du, u, t) -> du .= f_or_f!(u, t)
        Df = (u, t) -> ForwardDiff.jacobian(u -> f_or_f!(u, t), u)
        Df! = (J, du, u, t) -> ForwardDiff.jacobian!(J, u -> f_or_f!(u, t), u)
        return RightHandSideFunction(f, f!, Df, Df!)
    elseif hasmethod(f_or_f!, NTuple{3, Any})
        f! = f_or_f!
        f = (u, t) -> f_or_f!(similar(u), u, t)
        Df = (u, t) -> ForwardDiff.jacobian((du, u) -> f_or_f!(du, u, t), similar(u), u)
        Df! = (J, du, u, t) -> ForwardDiff.jacobian!(J, (du, u) -> f_or_f!(du, u, t), du, u)
        return RightHandSideFunction(f, f!, Df, Df!)
    end
end
@doc (@doc RightHandSideFunction) RHS(args...; kwargs...) = RightHandSideFunction(args...; kwargs...)

@doc """
    InitialValueProblem(rhs, u0, tspan) -> InitialValueProblem
    InitialValueProblem(rhs, u0, t0, tN) -> InitialValueProblem
    IVP(args...; kwargs...) -> InitialValueProblem

returns a constructor for an initial value problem.

# Arguments
- `rhs   :: Union{Function, RightHandSideFunction}` : right-hand side derivative.
- `u0    :: Union{Number, AbstractVector}`          : initial condition.
- `tspan :: Tuple{Real, Real}`                      : time domain.
- `t0    :: Real`                                   : initial time.
- `tN    :: Real`                                   : final time.
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

"""
    Dahlquist(; u0 = 1.0, tspan = (0.0, 1.0), λ = 1.0) -> InitialValueProblem

returns an `InitialValueProblem` for the Dahlquist equation.
"""
function Dahlquist(; u0 = 1.0, tspan = (0.0, 1.0), λ = 1.0)
    f!(du, u, t) = @. du = λ * u
    return IVP(f!, u0, tspan)
end

"""
    Logistic(; u0 = 0.5, tspan = (0.0, 5.0), λ = 1.0) -> InitialValueProblem

returns an `InitialValueProblem` for the Logistic equation.
"""
function Logistic(; u0 = 0.5, tspan = (0.0, 5.0), λ = 1.0)
    f!(du, u, t) = @. du = λ * u * (1.0 - u)
    return IVP(f!, u0, tspan)
end

"""
    Riccati(; u0 = 0.0, tspan = (0.0, 5.0)) -> InitialValueProblem

returns an `InitialValueProblem` for the Riccati equation.
"""
function Riccati(; u0 = 0.0, tspan = (0.0, 5.0))
    f!(du, u, t) = @. du = u - t * u^2 + t
    return IVP(f!, u0, tspan)
end

"""
    SimplePendulum(; u0 = [0.0, π/2], tspan = (0.0, 2π), g = 1.0, L = 1.0) -> InitialValueProblem

returns an `InitialValueProblem` for the simple pendulum problem.
"""
function SimplePendulum(; u0 = [0.0, π/2], tspan = (0.0, 2π), g = 1.0, L = 1.0)
    function f!(du, u, t)
        du[1] = u[2]
        du[2] = -g/L * sin(u[1])
        return du
    end
    return IVP(f!, u0, tspan)
end

"""
    VanderPol(; u0 = [1.0; 0.0], tspan = (0.0, 5.0), μ = 1.0) -> InitialValueProblem

returns an `InitialValueProblem` for the Van der Pol equation (in first-order form).
"""
function VanderPol(; u0 = [1.0; 0.0], tspan = (0.0, 5.0), μ = 1.0)
    function f!(du, u, t)
        du[1] = u[2]
        du[2] = μ * (1.0 - u[1]^2) * u[2] - u[1]
        return du
    end
    return IVP(f!, u0, tspan)
end

"""
    Lorenz(; u0 = [2.0, 3.0, -14.0], tspan = (0.0, 10.0), σ = 10.0, β = 8/3, ρ = 28.0) -> InitialValueProblem

returns an `InitialValueProblem` for the Lorenz equations.
"""
function Lorenz(; u0 = [2.0, 3.0, -14.0], tspan = (0.0, 10.0), σ = 10.0, β = 8/3, ρ = 28.0)
    function f!(du, u, t)
        du[1] = σ * (u[2] - u[1])
        du[2] = u[1] * (ρ - u[3]) - u[2]
        du[3] = u[1] * u[2] - β * u[3]
        return du
    end
    return IVP(f!, u0, tspan)
end

"""
    Rössler(; u0 = [2.0, 0.0, 0.0], tspan = (0.0, 10.0), a = 0.2, b = 0.2, c = 5.7) -> InitialValueProblem

returns an `InitialValueProblem` for the Rössler equations.
"""
function Rössler(; u0 = [2.0, 0.0, 0.0], tspan = (0.0, 10.0), a = 0.2, b = 0.2, c = 5.7)
    function f!(du, u, t)
        du[1] = - u[2] - u[3]
        du[2] = u[1] + a * u[2]
        du[3] = b + u[3] * (u[1] - c)
        return du
    end
    return IVP(f!, u0, tspan)
end