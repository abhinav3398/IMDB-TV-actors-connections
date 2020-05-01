abstract type Frontier end

mutable struct Node
    state :: Union{Nothing, Integer, Node}
    parent :: Union{Nothing, Integer, Node}
    action :: Union{Nothing, Integer, Node}
end

mutable struct StackFrontier <: Frontier
    frontier :: Array{Node, 1};
    StackFrontier() = new();
end

function add(frontier :: T, node :: Node) where T <: Frontier
    push!(frontier.frontier, node)
end

function contains_state(frontier :: T, state :: W) where T <: Frontier where W <: Integer
    return any(node->node.state == state, frontier.frontier)
end

function empty(frontier :: T) where T <: Frontier
    return length(frontier.frontier) == 0
end

function remove(frontier :: StackFrontier)
    if empty(frontier)
        throw(DomainError("empty frontier"));
    else
        return pop!(frontier.frontier);
    end
end

mutable struct QueueFrontier <: Frontier
    frontier :: Array{Node, 1};
    QueueFrontier() = new();
end

function remove(frontier :: QueueFrontier)
    if empty(frontier)
        throw(DomainError("empty frontier"));
    else
        return popfirst!(frontier.frontier);
    end
end