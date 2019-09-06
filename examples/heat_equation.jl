"""
Solve the heat equation ∂ₜu = Δu on [0,1] using OrdinaryDiffEq for time stepping.
Boundary conditions are such that an analytic solution is given by:
    sin(2π*x) * exp(-(2*π)^2*t)

This example demonstrates how to solve time dependent PDE's combining `fenics` and `DiffEq`.

"""
module HeatEquationExample

using Test
using OrdinaryDiffEq
using FEniCS

mesh = UnitIntervalMesh(20)
V = FunctionSpace(mesh,"P",1)
u_str = "sin(2*pi*x[0]) * exp(-t*pow(2*pi, 2))"

u = interpolate(Expression(u_str, degree=2, pi=Float64(pi), t=0), V)

bc = DirichletBC(V, 0.0, "on_boundary")
dudt = TrialFunction(V)
v = TestFunction(V)
Dudt = FeFunction(V)
F = dot(dudt, v)*dx + dot(grad(u), grad(v))*dx
a = lhs(F)
L = rhs(F)
p = (u=u, Dudt=Dudt, bc=bc, a=a, L=L)

function f!(dudt_vec, u_vec, p, t)
    assign(p.u, u_vec)
    lvsolve(p.a, p.L, p.Dudt, p.bc)
    copy!(dudt_vec, get_array(p.Dudt))
end

u0_vec = get_array(u)
t_final = 0.1
tspan = (0.0, t_final)
prob = ODEProblem(f!, u0_vec, tspan, p)
u_true = interpolate(Expression(u_str, degree=2, pi=Float64(pi), t=t_final), V)

alg = ImplicitEuler(autodiff=false)
sol = OrdinaryDiffEq.solve(prob, alg)

vec_sol = get_array(p.u)
vec_true = get_array(u_true)
@test vec_sol ≈ vec_true rtol=1e-3

end#module
