local FiniteStateMachine = {}

function FiniteStateMachine.newMachine(states, initialState)
    local machine = {state = initialState}

    for _, state in pairs(states) do
        machine[state] = {}
    end

    return machine
end

function FiniteStateMachine.addTransition(machine, initialState, nextState, transition)
    machine[initialState][nextState] = transition
end

function FiniteStateMachine.toState(machine, nextState)
    local output = machine[machine.state][nextState]
    machine.state = nextState
    return output
end

return FiniteStateMachine