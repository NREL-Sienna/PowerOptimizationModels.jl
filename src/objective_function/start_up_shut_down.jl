get_shutdown_cost_value(
    container::OptimizationContainer,
    component::PSY.Component,
    time_period::Int,
    is_time_variant_::Bool,
) = _lookup_maybe_time_variant_param(
    container,
    component,
    time_period,
    Val(is_time_variant_),
    PSY.get_shut_down ∘ PSY.get_operation_cost,
    ShutdownCostParameter(),
)

function add_shut_down_cost!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {T <: PSY.Component, U <: VariableType, V <: AbstractDeviceFormulation}
    multiplier = objective_function_multiplier(U(), V())
    for d in devices
        PSY.get_must_run(d) && continue

        add_as_time_variant = is_time_variant(PSY.get_shut_down(PSY.get_operation_cost(d)))
        for t in get_time_steps(container)
            my_cost_term = get_shutdown_cost_value(
                container,
                d,
                t,
                add_as_time_variant,
            )
            iszero(my_cost_term) && continue
            exp = _add_proportional_term_maybe_variant!(
                Val(add_as_time_variant), container, U(), d, my_cost_term * multiplier,
                t)
            add_cost_to_expression!(container, ProductionCostExpression, exp, d, t)
        end
    end
    return
end

function add_start_up_cost!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {T <: PSY.Component, U <: VariableType, V <: AbstractDeviceFormulation}
    for d in devices
        op_cost_data = PSY.get_operation_cost(d)
        _add_start_up_cost_to_objective!(container, U(), d, op_cost_data, V())
    end
    return
end

function _add_start_up_cost_to_objective!(
    container::OptimizationContainer,
    ::T,
    component::PSY.ThermalGen,
    op_cost::Union{PSY.ThermalGenerationCost, PSY.MarketBidCost},
    ::U,
) where {T <: VariableType, U <: AbstractDeviceFormulation}
    multiplier = objective_function_multiplier(T(), U())
    PSY.get_must_run(component) && return
    add_as_time_variant = is_time_variant(PSY.get_start_up(op_cost))
    for t in get_time_steps(container)
        my_cost_term = get_startup_cost_value(
            container,
            T(),
            component,
            U(),
            t,
            add_as_time_variant,
        )
        iszero(my_cost_term) && continue
        exp = _add_proportional_term_maybe_variant!(
            Val(add_as_time_variant), container, T(), component,
            my_cost_term * multiplier, t)
        add_cost_to_expression!(container, ProductionCostExpression, exp, component, t)
    end
    return
end

function get_startup_cost_value(
    container::OptimizationContainer,
    ::T,
    component::V,
    ::U,
    time_period::Int,
    is_time_variant_::Bool,
) where {T <: VariableType, V <: PSY.Component, U <: AbstractDeviceFormulation}
    raw_startup_cost = _lookup_maybe_time_variant_param(
        container,
        component,
        time_period,
        Val(is_time_variant_),
        PSY.get_start_up ∘ PSY.get_operation_cost,
        StartupCostParameter(),
    )
    # TODO add stub for start_up_cost.
    return start_up_cost(raw_startup_cost, component, T(), U())
end
