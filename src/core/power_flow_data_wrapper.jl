# Stub type when PowerFlows extension is not loaded
# The actual implementation is in ext/PowerFlowsExt.jl
mutable struct PowerFlowEvaluationData{T}
    power_flow_data::T
    input_key_map::Dict{Symbol, <:Dict{<:OptimizationContainerKey, <:Any}}
    is_solved::Bool
end

# Stub functions - actual implementations in extension
function check_network_reduction(container)
    @warn "PowerFlows extension not loaded. Power flow evaluation is not available."
    return nothing
end

function PowerFlowEvaluationData(power_flow_data)
    error(
        "PowerFlows extension not loaded. Please load PowerFlows to use power flow evaluation: using PowerFlows",
    )
end

function get_power_flow_data(ped::PowerFlowEvaluationData)
    return ped.power_flow_data
end

function get_input_key_map(ped::PowerFlowEvaluationData)
    return ped.input_key_map
end
