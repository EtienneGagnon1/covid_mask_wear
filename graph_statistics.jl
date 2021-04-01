using CSV
using DataFrames
using LightGraphs
using JLD
using GraphPlot
using Statistics
using StatsBase
using MetaGraphs
using NetworkLayout:SFDP
using Colors
using Cairo
using Compose


include("personalized_pagerank.jl")

path_to_data = "data"

path_to_graph_data = "graph_data"
vertex_id_map_file = "vertex_id_map.jld"
path_to_graph = "filtered_network.lg"

path_to_special_accounts = "canadian_special_accounts.csv"


canadian_accounts_data = CSV.read(
joinpath(path_to_data, path_to_special_accounts), DataFrame)

graph_data = JLD.load(
joinpath(path_to_data, path_to_graph_data, vertex_id_map_file))

id_map = get(graph_data, "id_int_map", 0)
rev_id_map = Dict(value => key for (key, value) in id_map)

academic_accounts_mask = [acc == "academic" for acc in  canadian_accounts_data[!, :type]]
academic_accounts = canadian_accounts_data[academic_accounts_mask, :]
friend_graph = LightGraphs.loadgraph(joinpath(path_to_data, path_to_graph))

academic_seeds = [
    185740620,
    191606313,
    4264597103,
    18776647,
    22266871,
    330574021,
    2176565550,
    573592279,
    95092020,
    22532501,
    67109130,
    78366138,
    21576515,
    90732175,
    16316758,
    18060714,
    1357259774,
    1726277852,
    151776255,
    3013302856,
    210855517,
    70760065,
    772225555,
    1236816024281976833,
    920096512540995584,
    1069101314,
    175471321,
    14452313,
    742166854752342016,
    20818272,
    47992614,
    968243063884664832,
    902219961820618752,
    211887326,
    862167372,
    232519990,
    14707010,
    610088998,
    1329747025,
    373536627,
    108649810,
    850001265325199360,
    18065266,
    57042914,
    42391676,
    3362437877,
    361870689,
    522319148,
    134868803,
    978317334967476225,
    537648764,
    1488787292,
    4061661014,
    440541024,
    69914884,
    890741330896355334,
    964014051457163265,
    1156723716664860672,
    394770831,
    1266016313983397888,
    887958433,
    820031371137744896,
    197146787,
    14133286,
    28453440,
    147330184,
    909266699710455808,
    64540763,
    1177641251983646720,
    61627131,
    24954656,
    1873246573,
    2675293657,
    274006595,
    1121170263578750976]

academic_nodes = [get(id_map, sd, nothing) for sd in academic_seeds]
academic_nodes = [x for x in academic_nodes if !isnothing(x)]

acad_pageranks = personalized_pagerank(friend_graph, academic_nodes)
pageranks = pagerank(friend_graph)

pagerank_df = DataFrame("node"=> 1:nv(friend_graph),
 "acad_pagerank" => acad_pageranks,
 "pagerank" => pageranks,
 "twitter_id" => [rev_id_map[x] for x in 1:nv(friend_graph)])

pr_ratio = pagerank_df[:, :acad_pagerank] ./ pagerank_df[:, :pagerank]
pagerank_df[:, :pr_ratio] = pr_ratio

pagerank_df = sort(pagerank_df, :pr_ratio, rev=true)
acad_accounts = first(pagerank_df, 5000)

#
# acad_nodes = acad_accounts[:, 1]
#
# all_nodes = pagerank_df[!, :node]
#
# sample_nodes = StatsBase.sample(all_nodes, 10000, replace=false)
#
# src_nodes = Set()
# dst_nodes = Set()
#
# for edge in edges(friend_graph)
#     if in(sample_nodes).(edge.src) && in(sample_nodes).(edge.dst)
#         source = edge.src
#         destination = edge.dst
#
#         push!(src_nodes, source)
#         push!(dst_nodes, destination)
#     end
#
# end
#
# src_dst_nodes = intersect(src_nodes, dst_nodes)
#
# sample_nodes_new_ids = Dict(src_dst_nodes .=> 1:length(src_dst_nodes))
# retained_nodes = Set(keys(sample_nodes_new_ids))
#
# sampled_edges = []
# for edge in edges(friend_graph)
#     if in(retained_nodes).(edge.src) && in(retained_nodes).(edge.dst)
#         new_edge = LightGraphs.Edge(sample_nodes_new_ids[edge.src], sample_nodes_new_ids[edge.dst])
#         push!(sampled_edges, new_edge)
#     end
# end
#
# sample_graph = LightGraphs.SimpleDiGraphFromIterator(sampled_edges)
# sample_graph = MetaGraphs.MetaDiGraph(sample_graph)
#
# sample_graph_ids = Set(1:nv(sample_graph))
#
# acad_nodes_new_ids = [get(sample_nodes_new_ids, node, 0) for node in acad_nodes]
# acad_nodes_new_ids = [x for x in acad_nodes_new_ids if x != 0]

#
# node_cols = []
# for node in 1:nv(friend_graph)
#     if node in acad_nodes
#         push!(node_cols, RGBA(0.584, 0.345, 0.698, 1))
#     else
#         push!(node_cols, RGBA(0.796, 0.235, 0.2, 1))
#     end
# end
#
# path_to_figures = "plots_and_figures"
# plot_file = "plot_acad_net.pdf"
# draw(PDF(joinpath(path_to_figures, plot_file), 100cm, 100cm), gplot(friend_graph,
# layout=spring_layout,
# edgelinewidth=0.01,
# EDGELINEWIDTH=0.01,
# arrowlengthfrac=0,
# nodefillc=node_cols))
