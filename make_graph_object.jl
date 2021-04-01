using LightGraphs
using CSV
using DataFrames
using JLD

function prepare_mapping(network_file)

    unique_accounts = unique(hcat(network_file[:, 1], network_file[:, 2]))
    matching_id = Array(1:length(unique_accounts))

    account_id_mapping = Dict(unique_accounts .=> matching_id)

    return account_id_mapping
end

function load_data_in_graph_object(graph_object, edge_data, mapping)
    add_vertices!(graph_object, length(keys(mapping)))
    num_edges = nrow(edge_data)

    key_err_count = 0
    for i in 1:num_edges
        try
            account = mapping[edge_data[i, 1]]
            relation = mapping[edge_data[i, 2]]

            add_edge!(graph_object, account, relation)
        catch KeyError
            key_err_count += 1
            continue
        end
    end
    print("found $key_err_count errors")

    return graph_object
end
println("starting to make graph object")

path_to_data = "data"
path_to_graph_data = "graph_data"

path_to_network = "friend_network_filtered.csv"
path_to_output_network = "filtered_network.lg"

path_to_id_int_map = "vertex_id_map.jld"

friend_network = CSV.read(joinpath(path_to_data, path_to_network), DataFrame)
friend_network = select(friend_network, [1, 2])

my_graph = LightGraphs.DiGraph()

id_int_mapping = prepare_mapping(friend_network)
my_graph = load_data_in_graph_object(my_graph, friend_network, id_int_mapping)

LightGraphs.savegraph(joinpath(path_to_data, path_to_output_network), my_graph)

JLD.save(joinpath(path_to_data, path_to_graph_data, path_to_id_int_map),
 "id_int_map", id_int_mapping)

print("saved graph object to $path_to_output_network")
