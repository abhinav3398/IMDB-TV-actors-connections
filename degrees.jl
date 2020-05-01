using CSV
using DataFrames

import Base.Threads.@spawn

include("util.jl")


# Maps names to a set of corresponding person_ids
names = Dict{String, Set}();

# Maps person_ids to a dictionary of: name, birth, movies (a set of movie_ids)
people = Dict{Int64, Dict{String, Any}}();

# Maps movie_ids to a dictionary of: title, year, stars (a set of person_ids)
movies = Dict{Int64, Dict{String, Any}}();

function load_data(directory::String)
    #=
    Load data from CSV files into memory. 
    =#
    # Load people
    people_data = CSV.read(directory*"/people.csv");
    for row ∈ 1:nrow(people_data)
        people[people_data[row, 1]] = Dict(
            "name" => people_data[row, 2], 
            "birth" => people_data[row, 3], 
            "movies" => Set()
        );
        if !(haskey(names, lowercase(people_data[row, 2])))
            names[lowercase(people_data[row, 2])] = Set(people_data[row, 1]);
        else
            push!(names[lowercase(people_data[row, 2])], people_data[row, 1]);
        end
    end

    # Load movies
    movies_data = CSV.read(directory*"/movies.csv");
    for row ∈ 1:nrow(movies_data)
        movies[movies_data[row, 1]] = Dict(
            "title" => movies_data[row, 2], 
            "year" => movies_data[row, 3], 
            "stars" => Set()
        );
    end

    # Load stars
    stars_data = CSV.read(directory*"/stars.csv");
    for row ∈ 1:nrow(stars_data)
        try 
            push!(people[stars_data[row, 1]]["movies"], stars_data[row, 2]);
            push!(movies[stars_data[row, 2]]["stars"], stars_data[row, 1]);
        catch KeyError
            # pass
        end
    end
end

function main()
    if length(ARGS) != 1
        println("Usage: julia degrees.jl [directory]");
        exit(1);
    end
    directory = ARGS[end];

    # Load data from files into memory
    println("Loading data...");
    load_data(directory);
    println("Data loaded.");

    print("Name: ");
    source =  person_id_for_name(readline());
    if (source == nothing)
        println("Person not found.");
        exit(1)
    end
    print("Name: ");
    target = person_id_for_name(readline())
    if (target == nothing)
        println("Person not found.");
        exit(1)
    end

    path = shortest_path(source, target);

    if path == nothing
        println("Not connected.");
    else
        degrees = length(path);
        println("$degrees degrees of seperation.");
        path = vcat([(nothing, source)], path);
        for i ∈ 1:degrees
            person1 = people[path[i][2]]["name"];
            person2 = people[path[i + 1][2]]["name"];
            movie = movies[path[i + 1][1]]["title"];
            println("$(i): $person1 and $person2 starred in $movie");
        end
    end
end

function shortest_path(source :: T, target :: T) where T <:Integer
    #= 
    Returns the shortest list of (movie_id, person_id) pairs
    that connect the source to the target.

    If no possible path, returns nothing. 
    =#
    
    # Keep track of number of states explored
    num_explored = 0

    # Initialize frontier to just the starting position
    start, goal = Node(source, nothing, nothing), target

    frontier = QueueFrontier()
    frontier.frontier = Node[]
    add(frontier, start)

    # Initialize an empty explored set
    explored = Set{Union{Nothing, Integer}}()
    path = Tuple{Union{Nothing, Integer, Node}, Union{Nothing, Integer, Node}}[]

    # Keep looping until solution found
    while true
        # If nothing left in frontier, then no path
        if empty(frontier)
            return nothing;
        end

        # Choose a node from the frontier
        node = remove(frontier);
        num_explored += 1;

        # If node is the goal, then we have a solution
        if node.state == goal
            while node.parent != nothing
                push!(path, (node.action, node.state));
                node = node.parent;
            end
            path = path[end:-1:1];
            return (path != []) ? path : nothing;
            
        end

        # Mark node as explored
        push!(explored, node.state);

        # Add neighbors to frontier
        for (action, state) in neighbors_for_person(node.state)
            if !(contains_state(frontier, state)) && !(state in explored)
                child = Node(state, node, action);
                add(frontier, child);
            end
        end
    end
end

function neighbors_for_person(person_id :: T) where T <:Integer
    #= 
    Returns (movie_id, person_id) pairs for people
    who starred with a given person. 
    =#
    movie_ids = people[person_id]["movies"];
    neighbors = Set();
    for movie_id ∈ movie_ids, person_id ∈ movies[movie_id]["stars"]
        push!(neighbors, (movie_id, person_id));
    end
    return neighbors;
end

function person_id_for_name(name::String)
    #= 
    Returns the IMDB id for a person's name,
    resolving ambiguities as needed. 
    =#
    person_ids = collect(get(names, lowercase(name), Set()));
    if length(person_ids) == 0
        return nothing;
    elseif length(person_ids) > 1
        print("Which '$name'?");
        for person_id ∈ person_ids
            person = people[person_id];
            name, birth = person["name"], person["birth"];
            println("ID: $person_id, Name: $name, birth: $birth");
        end
        try 
            print("Intended Person ID: ");
            person_id = readline();
            if person_id ∈ person_ids
                return person_id;
            end
        catch ArgumentError
            # pass
        end
        return nothing;
    else
        return first(person_ids);
    end
end

main()