


# Lag, Spelade, Vunna, Oavgjorda, Förlorade, Gjorda Mål, Insläppta Mål, Måldifferens, Poäng, Poängsnitt
# T, GP, W, D, L, GF, GA, GD, PTS, PA
# Team, GamesPlayed, Wins, Draws, Losses, GoalsFor, GoalsAgainst, GoalDifference, Points, PointAverage


function outcome(homeScore,awayScore)
	if homeScore>awayScore
		:HomeVictory
	elseif homeScore<awayScore
		:AwayVictory
	else
		:Draw
	end
end

function sorttable!(table::DataFrame)
	sort!(table, [order(:Points, rev=true),
		          order(:GoalDifference, rev=true),
		          order(:GoalsFor, rev=true)])
end

# construct Home/Away tables by using incHome/incAway
function addgame!(T::DataFrame, games::DataFrame, g::Int; winPoints=3, incHome=true, incAway=true)
	teams = T[:Team]
	homeRow = findfirst(isequal(games[g,:HomeTeam]),teams)
	awayRow = findfirst(isequal(games[g,:AwayTeam]),teams)

	homeScore = games[g,:HomeScore]
	awayScore = games[g,:AwayScore]


	incHome && (T[homeRow,:GamesPlayed] += 1)
	incAway && (T[awayRow,:GamesPlayed] += 1)

	incHome && (T[homeRow,:GoalsFor] += homeScore)
	incAway && (T[awayRow,:GoalsFor] += awayScore)

	incHome && (T[homeRow,:GoalsAgainst] += awayScore)
	incAway && (T[awayRow,:GoalsAgainst] += homeScore)

	incHome && (T[homeRow,:GoalDifference] += homeScore-awayScore)
	incAway && (T[awayRow,:GoalDifference] += awayScore-homeScore)


	oc = outcome(homeScore,awayScore)

	# possibly correct outcome
	if haskey(games,:Outcome) && !ismissing(games[g,:Outcome])
		oc = Symbol(games[g,:Outcome])
	end


	incHome && (T[homeRow,:Wins] += oc==:HomeVictory)
	incAway && (T[awayRow,:Wins] += oc==:AwayVictory)

	incHome && (T[homeRow,:Draws] += oc==:Draw)
	incAway && (T[awayRow,:Draws] += oc==:Draw)

	incHome && (T[homeRow,:Losses] += oc==:AwayVictory)
	incAway && (T[awayRow,:Losses] += oc==:HomeVictory)

	homePoints = (oc==:HomeVictory)*winPoints + (oc==:Draw)
	awayPoints = (oc==:AwayVictory)*winPoints + (oc==:Draw)

	# possibly correct points
	if haskey(games,:PointsDeductedHome) && !ismissing(games[g,:PointsDeductedHome])
		homePoints -= games[g,:PointsDeductedHome]
	end
	if haskey(games,:PointsDeductedAway) && !ismissing(games[g,:PointsDeductedAway])
		awayPoints -= games[g,:PointsDeductedAway]
	end

	incHome && (T[homeRow,:Points] += homePoints)
	incAway && (T[awayRow,:Points] += awayPoints)
	T
end


function table(games::DataFrame; kwargs...)
	teams = sort(unique(vcat(games[:HomeTeam], games[:AwayTeam])))

	# unsorted table
	T = DataFrame(Team=teams)
	T[[:GamesPlayed, :Wins, :Draws, :Losses, :GoalsFor, :GoalsAgainst, :GoalDifference, :Points]] = 0

	# Compute everything for this game
	for g=1:size(games,1)
		addgame!(T, games, g; kwargs...)
	end

	T[:PointAverage] = T[:Points] ./ T[:GamesPlayed]
	sorttable!(T)
end


# assumes dest and table have exactly the same columns
function _addtable(dest, table)
	@assert names(dest)==names(table)

	for i=1:size(table,1)
		team = table[i,:Team]
		destRow = findfirst(isequal(team), dest[:Team])

		if destRow!=nothing # add to existing row
			for j=2:size(table,2)
				dest[destRow,j] += table[i,j]
			end
		else # create new row
			append!(dest, table[i,:])
		end
	end
end

# create marathon table - adds Seasons column
function mergetables(tables...)
	merged = DataFrame(Team=String[], GamesPlayed=Int[], Wins=Int[], Draws=Int[], Losses=Int[], GoalsFor=Int[], GoalsAgainst=Int[], GoalDifference=Int[], Points=Int[], Seasons=Int[])

	for table in tables
		table = copy(table) # copy before changing
		table[:Seasons] = 1 # all teams get one season from this table
		deletecols!(table, :PointAverage) # remove point average and recompute it later

		@assert names(merged) == names(table)

		_addtable(merged, table)
	end
	merged[:PointAverage] = merged[:Points] ./ merged[:GamesPlayed]
	sorttable!(merged)
end


defaultresultsfolder() = joinpath(dirname(pathof(Allsvenskan)),"..","data","results")


function allgamesbyseason(folder::String=defaultresultsfolder())
	files = readdir(folder)
	filter!(x->lowercase(splitext(x)[2])==".csv", files)
	# exit.(joinpath.([folder],files))
	# CSV.read.(joinpath.([folder],files), missingstring="NA")
	CSV.read.(joinpath.([folder],files), categorical=false,missingstring="NA",strings=:raw,rows_for_type_detect=10000)
end

allgames(G::AbstractArray{DataFrame}) = _vcat(G...)
allgames(folder::String=defaultresultsfolder()) = allgames(allgamesbyseason(folder))

alltables(G::AbstractArray{DataFrame}) = table.(G)
alltables(folder::String=defaultresultsfolder()) = alltables(allgamesbyseason(folder))

allteams(g::DataFrame) = unique(convert(Vector{String},vcat(g[:HomeTeam],g[:AwayTeam])))
allteams(folder::String=defaultresultsfolder()) = allteams(allgames(folder))




function filterbyteam!(G, allTeams, teams, cols=[:HomeTeam,:AwayTeam])
    if !all(x->x in allTeams, teams)
        i = findfirst(x->!(x in allTeams), teams)
        error("Unknown team: \"", teams[i], "\". Did you mean: \"",
              didyoumean(allTeams, teams[i]), "\"?")
    end

    for col in cols
        for i=1:size(G,1)
            mask = map!(x-> x in teams, BitVector(undef,size(G[i],1)), G[i][col])
            G[i] = G[i][mask,:]
        end
    end
    G
end


function marathon(; folder=defaultresultsfolder(), seasons=1:100000,
                  teams=nothing, turf=:both, kwargs...)
    @assert turf in [:both, :home, :away]

    G = allgamesbyseason(folder)
    allTeams = unique(vcat( map(x->x[:HomeTeam],G)..., map(x->x[:AwayTeam],G)... ))

    filter!(x-> Dates.year(Date(x[1,:Date])) in seasons, G)

    teams==nothing || filterbyteam!(G, allTeams, teams)

    incHome = turf==:both || turf==:home
    incAway = turf==:both || turf==:away

    mergetables(table.(G;incHome=incHome,incAway=incAway,kwargs...)...)
end
