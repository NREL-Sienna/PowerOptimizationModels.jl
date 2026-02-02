# add_proportional_cost! is used for Thermals (a bunch) and ControllableLoads (once) in POM
# add_proportional_cost_maybe_time_variant! is used to define a add_proportional_cost! in
# POM, for Thermals and ControllableLoads with certain formulations.
# _add_proportional_term! is used in linear_curve, quadratic_curve, and mbc objective functions implementations.

function _add_proportional_term_helper(
    container::OptimizationContainer,
    ::T,
    component::U,
    linear_term::Float64,
    time_period::Int,
) where {T <: VariableType, U <: IS.InfrastructureSystemsComponent}
    component_name = get_name(component)
    @debug "Linear Variable Cost" _group = LOG_GROUP_COST_FUNCTIONS component_name
    variable = get_variable(container, T(), U)[component_name, time_period]
    lin_cost = variable * linear_term
    return lin_cost
end

# Invariant
# used in linear, quadratic, and mbc objective functions implementations.
function _add_proportional_term!(
    container::OptimizationContainer,
    ::T,
    component::U,
    linear_term::Float64,
    time_period::Int,
) where {T <: VariableType, U <: IS.InfrastructureSystemsComponent}
    lin_cost = _add_proportional_term_helper(
        container, T(), component, linear_term, time_period)
    add_to_objective_invariant_expression!(container, lin_cost)
    return lin_cost
end

# Variant
function _add_proportional_term_variant!(
    container::OptimizationContainer,
    ::T,
    component::U,
    linear_term::Float64,
    time_period::Int,
) where {T <: VariableType, U <: IS.InfrastructureSystemsComponent}
    lin_cost = _add_proportional_term_helper(
        container, T(), component, linear_term, time_period)
    add_to_objective_variant_expression!(container, lin_cost)
    return lin_cost
end

# Maybe variant
_add_proportional_term_maybe_variant!(
    ::Val{false},
    container::OptimizationContainer,
    ::T,
    component::U,
    linear_term::Float64,
    time_period::Int,
) where {T <: VariableType, U <: IS.InfrastructureSystemsComponent} =
    _add_proportional_term!(container, T(), component, linear_term, time_period)
_add_proportional_term_maybe_variant!(
    ::Val{true},
    container::OptimizationContainer,
    ::T,
    component::U,
    linear_term::Float64,
    time_period::Int,
) where {T <: VariableType, U <: IS.InfrastructureSystemsComponent} =
    _add_proportional_term_variant!(container, T(), component, linear_term, time_period)

# this is only used for ControllableLoads with non-PowerLoadInterruptible formulations. 
# The rest go through a thin wrapper around the maybe-variant version.
"""
Default implementation for proportional cost, where the cost term is not time variant. Anything 
time-varying should implement its own method.
"""
function add_proportional_cost!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {
    T <: IS.InfrastructureSystemsComponent,
    U <: VariableType,
    V <: AbstractDeviceFormulation,
}
    # NOTE: anything time-varying should implement its own method.
    multiplier = objective_function_multiplier(U(), V())
    for d in devices
        op_cost_data = get_operation_cost(d)
        cost_term = proportional_cost(op_cost_data, U(), d, V())
        iszero(cost_term) && continue
        for t in get_time_steps(container)
            exp = _add_proportional_term!(container, U(), d, cost_term * multiplier, t)

            add_cost_to_expression!(container, ProductionCostExpression, exp, d, t)
        end
    end
    return
end

# corresponds to get_must_run for thermals, but avoiding device specific code here.
"""
Extension point: whether to skip adding proportional cost for a given device.
For thermals, equivalent to `get_must_run`, but that implementation belongs in POM.
"""
skip_proportional_cost(d::IS.InfrastructureSystemsComponent) = false

"""
Common basis for maybe time variant proportional costs for devices that might have must-run behavior.
Currently used for `(ThermalGen, AbstractThermal)` and `(ControllableLoad, PowerLoadInterruption)` 
device, formulation pairs.
"""
function add_proportional_cost_maybe_time_variant!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {
    T <: IS.InfrastructureSystemsComponent,
    U <: VariableType,
    V <: AbstractDeviceFormulation,
}
    multiplier = objective_function_multiplier(U(), V())
    for d in devices
        op_cost_data = get_operation_cost(d)
        for t in get_time_steps(container)
            cost_term = proportional_cost(container, op_cost_data, U(), d, V(), t)
            add_as_time_variant =
                is_time_variant_term(container, op_cost_data, U(), d, V(), t)
            iszero(cost_term) && continue
            cost_term *= multiplier
            exp = if skip_proportional_cost(d)
                cost_term  # note we do not add this to the objective function
            else
                _add_proportional_term_maybe_variant!(
                    Val(add_as_time_variant), container, U(), d, cost_term, t)
            end
            add_cost_to_expression!(container, ProductionCostExpression, exp, d, t)
        end
    end
    return
end
