
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



function showmarathon(; folder=defaultresultsfolder(), seasons=1:100000, 
                        teams=nothing, turf=:both, kwargs...)
    @assert turf in [:both, :home, :away]

    G = allgamesbyseason(folder)
    allTeams = unique(vcat( map(x->x[:HomeTeam],G)..., map(x->x[:AwayTeam],G)... ))

    filter!(x-> Dates.year(Date(x[1,:Date])) in seasons, G)

    teams==nothing || filterbyteam!(G, allTeams, teams)

    incHome = turf==:both || turf==:home
    incAway = turf==:both || turf==:away

    T = mergetables(table.(G;incHome=incHome,incAway=incAway,kwargs...)...)
    printtable(T)
end



function head2head(teamA, teamB, folder, seasons=1:100000;
                   turf=:both)
    @assert turf in [:both, :home, :away]

    G = allgamesbyseason(folder)
    allTeams = unique(vcat( map(x->x[:HomeTeam],G)..., map(x->x[:AwayTeam],G)... ))

    filter!(x-> Dates.year(Date(x[1,:Date])) in seasons, G)

    homeTeams = String[]
    awayTeams = String[]
    if turf==:both || turf==:home
        push!(homeTeams, teamA)
        push!(awayTeams, teamB)
    end
    if turf==:both || turf==:away
        push!(homeTeams, teamB)
        push!(awayTeams, teamA)
    end
    filterbyteam!(G, allTeams, homeTeams, [:HomeTeam])
    filterbyteam!(G, allTeams, awayTeams, [:AwayTeam])


    T = mergetables(table.(G)...)

    TA = T[T[:Team].==teamA, :]
    TB = T[T[:Team].==teamB, :]

    (size(TA,1)==0 || size(TB,1)==0) && return ""

    # (Spelade, Vunna, Oavgjorda, Förlorade, Målskillnad, Poäng för teamA – poäng för teamB)
    string(TA[1,:GamesPlayed], ' ', TA[1,:Wins], ' ', TA[1,:Draws], ' ', TA[1,:Losses], ' ', TA[1,:GoalsFor], '-', TA[1,:GoalsAgainst], ' ', TA[1,:Points], '-', TB[1,:Points])
end


function showhead2head(teamA, teamB;
                       folder=defaultresultsfolder(),
                       seasons=1:100000)
    println("(Spelade, Vunna, Oavgjorda, Förlorade, Målskillnad, Poäng för $teamA – poäng för $teamB)")
    println("Alla matcher: ", head2head(teamA, teamB, folder, seasons, turf=:both))
    println("Hemmamatcher för $teamA: ", head2head(teamA, teamB, folder, seasons, turf=:home))
    println("Bortamatcher för $teamA ", head2head(teamA, teamB, folder, seasons, turf=:away))
end



function showgames(; folder=defaultresultsfolder(), seasons=1:100000, 
                     teams=String[], home=String[], away=String[])
    G = allgamesbyseason(folder)
    allTeams = unique(vcat( map(x->x[:HomeTeam],G)..., map(x->x[:AwayTeam],G)... ))

    filter!(x-> Dates.year(Date(x[1,:Date])) in seasons, G)

    # put single strings in array
    typeof(teams)<:AbstractString && (teams=[teams])
    typeof(home) <:AbstractString && (home =[home])
    typeof(away) <:AbstractString && (away =[away])

    # add teams to both home/away
    home = unique(vcat(home, teams))
    away = unique(vcat(away, teams))

    filterbyteam!(G, allTeams, home, [:HomeTeam])
    filterbyteam!(G, allTeams, away, [:AwayTeam])

    G = _vcat(G...)
    @assert size(G,1)>0 "No games to show."
    printgames(G)
end



