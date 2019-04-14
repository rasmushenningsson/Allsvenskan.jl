module Allsvenskan

using DataFrames
using CSV
using Missings
using StringDistances
using Dates
using Printf


export 
	addgame!,
	table,
	mergetables,
    allgamesbyseason,
    allgames,
    alltables,
    allteams,
    marathon,
    showmarathon,
    showhead2head,
    showgames

include("table.jl")
include("utils.jl")
include("show.jl")
include("city.jl")

end