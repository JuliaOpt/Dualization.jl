"""
    supported_constraints(constr_types::Vector{Tuple{DataType, DataType}})

Throws an error if a constraint is not supported to be dualized
"""
function supported_constraints(constr_types::Vector{Tuple{DataType, DataType}})
    for constr_type in constr_types
        constr_func = constr_type[1]
        constr_set = constr_type[2]
        if !supported_constraint(constr_func, constr_set)
            error("""
                oops!
            """)
        end
    end
    return nothing
end

# General case
supported_constraint(::DataType, ::DataType) = false
# List of supported constraints
supported_constraint(::Type{SAF{T}}, ::Type{MOI.GreaterThan{T}}) where T = true
supported_constraint(::Type{SAF{T}}, ::Type{MOI.LessThan{T}}) where T = true
#TODO

"""
    supported_objective(obj_func_type::DataType)

Throws an error if an objective function is not supported to be dualized
"""
function supported_objective(obj_func_type::DataType)
    if !supported_constraint(obj_func_type)
        error("""
            oops!
        """)
    end
    return nothing
end

# Genral case
supported_objective(::DataType) = false
# List of supported objective functions
supported_objective(::Type{SAF{T}}) where T = true
#TODO