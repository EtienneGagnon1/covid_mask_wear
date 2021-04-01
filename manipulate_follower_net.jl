using DataFrames
using CSV
using RData

function filter_out_df(friend_id, user_id)
    friend_id_matches = Vector{Bool}(undef, length(friend_id))

    user_id_set = Set(user_id)

    @Threads.threads for id_index in 1:length(friend_id)
        cur_id = friend_id[id_index]
        id_matched = in(user_id_set).(cur_id)
        friend_id_matches[id_index] = id_matched
    end

    return friend_id_matches
end

println("starting to process data file")
path_to_data = "data"
path_to_network_file = "friend_network.csv"
output_file = "friend_network_filtered.csv"

network_file = CSV.read(
joinpath(path_to_data, path_to_network_file), DataFrames.DataFrame)

network_file = select(network_file, [1, 2])

@assert !("date" in names(network_file))

friend_ids = network_file[:, 2]
user_ids = network_file[:, 1]

matched_links = filter_out_df(friend_ids, user_ids)
network_file_filtered = network_file[matched_links, :]

main_acc = Set(user_ids)

println(setdiff(unique_user_ids, main_acc))

@assert issubset(acc_relation, unique_user_ids)
issubset(main_acc, unique_user_ids)

CSV.write(joinpath(path_to_data, output_file), network_file_filtered)
println("filtered data saved to $output_file")
