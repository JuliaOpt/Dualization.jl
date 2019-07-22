function add_dual_equality_constraints(dual_model::MOI.ModelLike, primal_model::MOI.ModelLike,
                                       primal_dual_map::PrimalDualMap, primal_objective::PrimalObjective{T},
                                       con_types::Vector{Tuple{DataType, DataType}}) where T
    
    dual_sense = MOI.get(dual_model, MOI.ObjectiveSense()) # Get dual model sense
    num_objective_terms = MOIU.number_of_affine_terms(T, get_saf(primal_objective)) # This is used to update the scalar_term_index
    list_of_primal_vis = MOI.get(primal_model, MOI.ListOfVariableIndices())

    scalar_term_index::Int = 1
    for primal_vi in list_of_primal_vis
        # Loop at every constraint to get the scalar affine terms
        scalar_affine_terms = get_scalar_affine_terms(primal_model, primal_dual_map.primal_con_dual_var, 
                                                      primal_vi, con_types, T)
        # Add constraint, the sense of a0 depends on the dual_model ObjectiveSense
        # If max sense scalar term is -a0 and if min sense sacalar term is a0
        if primal_vi == primal_objective.saf.terms[scalar_term_index].variable_index
            scalar_term_value = MOI.coefficient(primal_objective.saf.terms[scalar_term_index])
            # This ternary is important for the last scalar_term_index
            # If the last term of the objective is not the last primal variable we don't update 
            # the scalar_term_index
            scalar_term_index == num_objective_terms ? scalar_term_index : scalar_term_index += 1
        else # In this case this variable is not on the objective function
            scalar_term_value = zero(T)
        end
        scalar_term = (dual_sense == MOI.MAX_SENSE ? 1 : -1) * scalar_term_value
        # Add equality constraint
        ci_dual = MOI.add_constraint(dual_model, MOI.ScalarAffineFunction(scalar_affine_terms, zero(T)), MOI.EqualTo(scalar_term))
        # Add primal variable to dual contraint to the link dictionary
        push!(primal_dual_map.primal_var_dual_con, primal_vi => ci_dual)
    end
    return 
end

function get_scalar_affine_terms(primal_model::MOI.ModelLike,
                                 primal_con_dual_var::Dict{CI, Vector{VI}}, primal_vi::VI,
                                 con_types::Vector{Tuple{DataType, DataType}}, T::DataType)
                                 
    scalar_affine_terms = Vector{MOI.ScalarAffineTerm{T}}(undef, 0) 
    for (F, S) in con_types
        primal_cis = MOI.get(primal_model, MOI.ListOfConstraintIndices{F,S}()) # Constraints of type {F, S}
        for ci in primal_cis
            fill_scalar_affine_terms!(scalar_affine_terms, primal_con_dual_var, 
                                      primal_model, ci, primal_vi) 
        end
    end
    return scalar_affine_terms
end

function push_to_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                      affine_term::T, vi::VI) where T

    if !iszero(affine_term) # if term is different than 0 add to the scalar affine terms vector
        push!(scalar_affine_terms, MOI.ScalarAffineTerm(affine_term, vi))
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{SAF{T}, S}, 
                                   primal_vi::VI) where {T, 
                                                         S <: Union{MOI.GreaterThan{T},
                                                                    MOI.LessThan{T},
                                                                    MOI.EqualTo{T}}}

    moi_function = get_function(primal_model, ci)
    for term in moi_function.terms
        if term.variable_index == primal_vi
            dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
            push_to_scalar_affine_terms!(scalar_affine_terms, MOI.coefficient(term), dual_vi)
        end
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{SVF, S}, 
                                   primal_vi::VI) where {T, 
                                                         S <: Union{MOI.GreaterThan{T},
                                                                    MOI.LessThan{T},
                                                                    MOI.EqualTo{T}}}

    moi_function = get_function(primal_model, ci)
    if moi_function.variable == primal_vi
        dual_vi = primal_con_dual_var[ci][1] # In this case we only have one vi
        push_to_scalar_affine_terms!(scalar_affine_terms, one(T), dual_vi)
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VAF{T}, S}, 
                                   primal_vi::VI) where {T, 
                                                         S <: MOI.AbstractVectorSet}

    moi_function = get_function(primal_model, ci)
    for term in moi_function.terms
        if term.scalar_term.variable_index == primal_vi
            dual_vi = primal_con_dual_var[ci][term.output_index] # term.output_index is the row of the VAF,
                                                                 # it corresponds to the dual variable associated with
                                                                 # this constraint
            push_to_scalar_affine_terms!(scalar_affine_terms, MOI.coefficient(term), dual_vi)
        end
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VVF, S}, 
                                   primal_vi::VI) where {T, 
                                                         S <: MOI.AbstractVectorSet}

    moi_function = get_function(primal_model, ci)
    for (i, variable) in enumerate(moi_function.variables)
        if variable == primal_vi
            dual_vi = primal_con_dual_var[ci][i]
            push_to_scalar_affine_terms!(scalar_affine_terms, one(T), dual_vi)
        end
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VAF{T}, MOI.PositiveSemidefiniteConeTriangle}, 
                                   primal_vi::VI) where T

    moi_function = get_function(primal_model, ci)
    moi_set = get_set(primal_model, ci)
    k::Int = 0
    for j in 1:moi_set.side_dimension
        for i in 1:j
            k += 1
            term = moi_function.terms[k]
            if term.scalar_term.variable_index == primal_vi
                dual_vi = primal_con_dual_var[ci][term.output_index] # term.output_index is the row of the VAF,
                                                                     # it corresponds to the dual variable associated with
                                                                     # this constraint
                if i == j
                    push_to_scalar_affine_terms!(scalar_affine_terms, one(T), dual_vi)
                else
                    push_to_scalar_affine_terms!(scalar_affine_terms, 2*one(T), dual_vi)
                end
            end
        end
    end
    return 
end

function fill_scalar_affine_terms!(scalar_affine_terms::Vector{MOI.ScalarAffineTerm{T}},
                                   primal_con_dual_var::Dict{CI, Vector{VI}},
                                   primal_model::MOI.ModelLike, ci::CI{VVF, MOI.PositiveSemidefiniteConeTriangle}, 
                                   primal_vi::VI) where T

    moi_function = get_function(primal_model, ci)
    moi_set = get_set(primal_model, ci)
    k::Int = 0
    for j in 1:moi_set.side_dimension
        for i in 1:j
            k += 1
            if moi_function.variables[k] == primal_vi
                dual_vi = primal_con_dual_var[ci][k]
                if i == j
                    push_to_scalar_affine_terms!(scalar_affine_terms, one(T), dual_vi)
                else
                    push_to_scalar_affine_terms!(scalar_affine_terms, 2*one(T), dual_vi)
                end
            end
        end
    end
    return 
end