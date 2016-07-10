module UNSflow

using Dierckx
export Spline1D, derivative, evaluate

using ForwardDiff
export derivative

#using PyPlot
#export plot, scatter, figure, xlabel, ylabel, xlim, ylim, xticks, yticks, subplot, axes

using Debug

using NLsolve
export nlsolve, not_in_place

export camber_calc, update_boundpos, update_kinem, update_indbound, update_downwash, update_a0anda1, place_tev, update_a2toan, mutual_ind, trapz, update_a2a3adot, update_bv, ind_vel, view_vorts, wakeroll, lautat, lautat_wakeroll, ldvm, calc_forces, design_solve, lesp_design_max, transfer_cm, ldvmstep

export KinemPar, MotionDef, KinemDef, EldUpDef, ConstDef, TwoDSurf, TwoDVort, TwoDFlowField, KelvinCondition, KelvinKutta, EldRampReturnDef, EldUpIntDef, SinDef, CosDef, KinemPar2DOF, TwoDSurf_2DOF, TwoDOFPar

include("types.jl")
include("calculations.jl")
include("solvers.jl")
include("postprocess.jl")

end
