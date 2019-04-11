function didyoumean(A,x)
    d = Float64[ compare(Levenshtein(), lowercase(a), lowercase(x)) for a in A ]
    i = indmax(d)
    A[i]
end


function _addmissing(df::AbstractDataFrame, cols::AbstractVector{Symbol})
    df = copy(df)
    for c in cols
        c in names(df) || (df[c] = missing)
    end
    df
end

function _vcat(args::AbstractDataFrame...)
    cols = unique(vcat(names.(args)...))
    vcat( [ _addmissing(df,cols) for df in args ]... )
end


function printtable(io::IO, T::DataFrame)
    A = Matrix{String}(size(T,1)+1, 11) # +1 for header
    P = Vector{Function}(11) # determines left or right padding
    S = Vector{String}(11)

    P[ 1]=rpad; S[ 1]=" "; A[:, 1]=vcat("Lag", map(string, T[:Team]))
    P[ 2]=lpad; S[ 2]=" "; A[:, 2]=vcat("Säs", map(string, T[:Seasons]))
    P[ 3]=lpad; S[ 3]=" "; A[:, 3]=vcat("S",   map(string, T[:GamesPlayed]))
    P[ 4]=lpad; S[ 4]=" "; A[:, 4]=vcat("V",   map(string, T[:Wins]))
    P[ 5]=lpad; S[ 5]=" "; A[:, 5]=vcat("O",   map(string, T[:Draws]))
    P[ 6]=lpad; S[ 6]=" "; A[:, 6]=vcat("F",   map(string, T[:Losses]))
    P[ 7]=lpad; S[ 7]="-"; A[:, 7]=vcat("GM",  map(string, T[:GoalsFor]))
    P[ 8]=rpad; S[ 8]=" "; A[:, 8]=vcat("IM",  map(string, T[:GoalsAgainst]))
    P[ 9]=lpad; S[ 9]=" "; A[:, 9]=vcat("D",   map(string, T[:GoalDifference]))
    P[10]=lpad; S[10]=" "; A[:,10]=vcat("P",   map(string, T[:Points]))
    P[11]=lpad; S[11]="";  A[:,11]=vcat("PS",  map(x->@sprintf("%.2f",x), T[:PointAverage]))

    # padding
    for (i,f) in enumerate(P)
        A[:,i] = f.(A[:,i], maximum(length.(A[:,i])))
    end

    for i=1:size(A,1)
        for j=1:size(A,2)
            print(io, A[i,j], S[j])
        end
        println(io)
    end
end
printtable(T::DataFrame) = printtable(STDOUT, T)



function printgames(io::IO, G::DataFrame)
    size(G,1)==0 && return
    A = Matrix{String}(size(G,1), 6)
    P = Vector{Function}(6) # determines left or right padding
    S = Vector{String}(6)

    P[ 1]=rpad; S[ 1]=" ";   A[:, 1]=map(string, G[:Date])
    P[ 2]=rpad; S[ 2]=" - "; A[:, 2]=map(string, G[:HomeTeam])
    P[ 3]=rpad; S[ 3]=" ";   A[:, 3]=map(string, G[:AwayTeam])
    P[ 4]=lpad; S[ 4]="-";   A[:, 4]=map(string, G[:HomeScore])
    P[ 5]=rpad; S[ 5]="";    A[:, 5]=map(string, G[:AwayScore])
    P[ 6]=rpad; S[ 6]="";    A[:, 6]="" # for extra notes

    # handle unusual extra fields
    if :Outcome in names(G)
        for i=1:size(A,1)
            o = G[i,:Outcome]
            if !isna(o)
                o=="HomeVictory" && (A[i,6] = string(A[i,6], ' ', G[i,:HomeTeam], " tilldömd segern."))
                o=="AwayVictory" && (A[i,6] = string(A[i,6], ' ', G[i,:AwayTeam], " tilldömd segern."))
            end
        end
    end
    if :PointsDeductedHome in names(G)
        for i=1:size(A,1)
            p = G[i,:PointsDeductedHome]
            isna(p) || (A[i,6] = string(A[i,6], ' ', p, " poängs avdrag för ", G[i,:HomeTeam], '.'))
        end
    end
    if :PointsDeductedAway in names(G)
        for i=1:size(A,1)
            p = G[i,:PointsDeductedAway]
            isna(p) || (A[i,6] = string(A[i,6], ' ', p, " poängs avdrag för ", G[i,:AwayTeam], '.'))
        end
    end


    # padding
    for (i,f) in enumerate(P)
        A[:,i] = f.(A[:,i], maximum(length.(A[:,i])))
    end

    for i=1:size(A,1)
        for j=1:size(A,2)
            print(io, A[i,j], S[j])
        end
        println(io)
    end
end
printgames(G::DataFrame) = printgames(STDOUT, G)
