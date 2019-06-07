"""
    set_dualmodel_sense!(dual_model::MOI.ModelLike, model::MOI.ModelLike)

Set the dual model objective sense
"""
function set_dual_model_sense(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike)
    # Get model sense
    primal_sense = MOI.get(primal_model, MOI.ObjectiveSense())
    if primal_sense == MOI.FEASIBILITY_SENSE
        error(primal_sense, " is not supported") # Feasibility should be supported?
    end
    # Set dual model sense
    dual_sense = (primal_sense == MOI.MIN_SENSE) ? MOI.MAX_SENSE : MOI.MIN_SENSE
    MOI.set(dual_model, MOI.ObjectiveSense(), dual_sense)
    return nothing
end

# Primals
"""
        PrimalObjectiveCoefficients{T}

Primal objective coefficients defined as ``a_0^Tx + b_0`` as in
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1

`affine_terms` corresponds to ``a_0``
`vi_vec` corresponds to ``x``
`constant` corresponds to ``b_0`` 
"""
struct PrimalObjectiveCoefficients{T}
    affine_terms::Vector{T}
    vi_vec::Vector{VI}
    constant::T
end

const POC{T} = PrimalObjectiveCoefficients{T}

"""
        get_POC(model::MOI.ModelLike)

Get the coefficients from the primal objective function and
return a `PrimalObjectiveCoefficients{T}`
"""
function get_POC(primal_sense::MOI.ModelLike)
    return _get_POC(primal_sense.objective)
end

function _get_POC(obj_fun::SAF{T}) where T
    # Empty vector a0 with the number of variables
    num_terms = length(obj_fun.terms)
    a0 = Vector{T}(undef, num_terms)
    vi = Vector{VI}(undef, num_terms)
    # Fill a0 for each term in the objective function
    i = 1::Int
    for term in obj_fun.terms
        a0[i] = term.coefficient # scalar affine coefficient
        vi[i] = term.variable_index # variable_index
        i += 1
    end
    b0 = obj_fun.constant # Constant term of the objective function
    PrimalObjectiveCoefficients(a0, vi, b0)
end

function _get_POC(obj_fun::SVF)
    a0 = [1.0] # Equals one on the SingleVariableFunction
    vi = [obj_fun.variable]
    b0 = 0.0 # SVF has no b0
    PrimalObjectiveCoefficients(a0, vi, b0)
end

# You can add other generic _get_POC functions here


# Duals
"""
        DualObjectiveCoefficients{T}

Dual objective coefficients defined as ``b_i^Ty + b_0`` or ``-b_i^Ty + b_0`` as in
http://www.juliaopt.org/MathOptInterface.jl/stable/apimanual/#Advanced-1

`affine_terms` corresponds to ``b_i`` 
`vi_vec` corresponds to ``y`` 
`constant` corresponds to ``b_0`` 
"""
struct DualObjectiveCoefficients{T}
    affine_terms::Vector{T}
    vi_vec::Vector{VI}
    constant::T
end

const DOC{T} = DualObjectiveCoefficients{T}

"""
        set_DOC(dualmodel::MOI.ModelLike, doc::DOC{T}) where T

Add the objective function to the dual model
"""
function set_DOC(dual_model::MOI.ModelLike, doc::DOC{T}) where T
    # Set dual model objective function
    MOI.set(dual_model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),  
            MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(doc.affine_terms, doc.vi_vec), doc.constant))
    return nothing
end

"""
        get_DOC(dual_model::MOI.ModelLike, dict_constr_coeffs::Dict, 
                dict_dualvar_primalcon::Dict, poc::POC{T}) where T

Get dual model objective function coefficients
"""
function get_DOC(dual_model::MOI.ModelLike, constr_coeffs::Dict, 
                 dual_var_primal_con::Dict, poc::POC{T}) where T

    sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense

    term_vec = Vector{T}(undef, dual_model.num_variables_created)
    vi_vec   = Vector{VI}(undef, dual_model.num_variables_created)
    for constr = 1:dual_model.num_variables_created # Number of constraints of the primal model
        vi = VI(constr)
        term = constr_coeffs[dual_var_primal_con[vi]][2] # Accessing bi
        # Add positive terms bi if dual model sense is max
        term_vec[constr] = (sense == MOI.MAX_SENSE ? -1 : 1) * term
        # Variable index associated with term bi
        vi_vec[constr] = vi
    end
    non_zero_terms = findall(!iszero, term_vec)
    return DOC(term_vec[non_zero_terms], vi_vec[non_zero_terms], poc.constant)
end