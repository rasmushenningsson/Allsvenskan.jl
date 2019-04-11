module Allsvenskan

using DataFrames
using CSV
using Missings
using StringDistances


export 
	addgame!,
	table,
	mergetables,
    allgamesbyseason,
    allgames,
    alltables,
    allteams,
    showmarathon,
    showhead2head,
    showgames

include("table.jl")
include("utils.jl")
include("show.jl")
include("city.jl")

end