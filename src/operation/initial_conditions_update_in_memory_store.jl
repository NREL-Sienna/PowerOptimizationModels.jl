
################## ic updates from store for emulation problems simulation #################

"""
    update_initial_conditions!(ics, store, resolution)

Update initial conditions from the emulation model store.
This is an extension point - concrete implementations for specific initial condition
types should be defined in PowerOperationsModels.

# Arguments
- `ics`: Vector of InitialCondition objects to update
- `store`: EmulationModelStore containing the recorded values
- `resolution`: Time resolution (Dates.Millisecond)
"""
function update_initial_conditions!(
    ics::Vector{<:InitialCondition},
    store::EmulationModelStore,
    resolution::Dates.Millisecond,
)
    # This is a stub - concrete implementations for specific initial condition types
    # (InitialTimeDurationOn, InitialTimeDurationOff, DevicePower, DeviceStatus, etc.)
    # should be defined in PowerOperationsModels.
    error(
        "update_initial_conditions! not implemented for initial condition type " *
        "$(eltype(ics)). Implement this method in PowerOperationsModels.",
    )
end
