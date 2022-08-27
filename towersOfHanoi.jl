
using Distributions
using StatsBase
using DataFrames

n=3

function move(State,m,n)
    newState=copy(State)
    if checkLegal(State,m,n)>0
        newState[n]=[newState[m][1];;newState[n]]
        newState[m]=newState[m][2:end]
        return newState
    end
end

function checkLegal(State,m,n) #Check the legality of the move: Moving the top disc from rung m to rung n when state=State
    if State[m]==[]
        return 0
    elseif State[n]==[]
        return 1
    elseif State[m][1]>State[n][1]
        return 0
    else 
        return 1
    end
end

State=[[1,2,3],[],[]]; #State is specified with the number indicating the size of the disc and represent the discs arranged top to bottom

function play(State,strat)
    visited=[State]
    J=Dict()
    oldState=copy(State)
    i=1
    while i<=length(strat)
        if checkLegal(oldState,strat[i][1],strat[i][2])>0
            println("Moved from $(strat[i][1]) to $(strat[i][2])")
            newState=move(oldState,strat[i][1],strat[i][2])
            println("$oldState\n")
            if !(newState in visited)
                push!(visited,newState)
                J[oldState,newState]=1
                J[newState,oldState]=1
                println("$newState\n")
            end
            i=i+1
            oldState=copy(newState)
        else
            println("Illegal Move")
            i=i+1
        end
    end
    return visited,J
end


            
finalState=[[],[1,2,3],[]]

movelist=vec([[i,j] for i=1:3,j=1:3 if !(i==j)])

randomStrat=Categorical(1/6*ones(6))

strat=movelist[rand(randomStrat,1000)]

visited,J=play(State,strat)

neighbour(a)=[move(a,s[1],s[2]) for s in movelist if move(a,s[1],s[2])!=nothing]


function StackedMatrix(State)
    StateMat=copy(State)
    for j in 1:3
        tempvec=ones(n)
        if length(StateMat[j])<n
            for i in 1:n-length(StateMat[j])
                tempvec[i]=0
            end
            if length(StateMat[j])!=0
                for i in 1:length(StateMat[j])
                    tempvec[i+n-length(StateMat[j])]=StateMat[j][i]
                end
            end
        end
        StateMat[j]=tempvec
    end
    return StateMat
end

function exhExplore(vertices,moves)
    J=Dict()
    for v in vertices
        for w in vertices
            J[v,w]=Inf
        end
    end

    for v in vertices
        for s in moves
            if checkLegal(v,s[1],s[2])==true
                newState=move(v,s[1],s[2])
                J[v,newState]=0
            end
        end
    end

    for v in vertices
        if finalState in neighbour(v)
            J[v,finalState]=100
        end
    end
    return J
end

function FloydWarshall(dist)
    println("Initial Adjacency matrix: ")
    display(dist)
    println("\n")
    n=length(visited)
    for k in 1:n
        println("Matrix A^k with k as ",k)
        println("Current dist:")
        display(dist)
        println("\n")
        for i in 1:n
            for j in 1:n 
                dist[i,j] = min(dist[i,j], dist[i,k] + dist[k,j])
            end
        end

    end
    println("\n Matrix after applying Floyd Warshall: ")
    display(dist)
    println("\n")
    return dist
end




M=fill(Inf,length(visited),length(visited))
for i in 1:length(visited)
    for j in 1:length(visited)
        M[i,j]= visited[j] in neighbour(visited[i]) ? 1 : Inf
    end
end

minDistMat=FloydWarshall(M)


function minMoves(State1,State2,M)
    i=findall(x->x==State1,visited)[1]
    j=findall(x->x==State2,visited)[1]
    return M[i,j]
end


#Implementing Q-Learning
R = zeros(length(visited),length(visited))
for i in 1:length(visited)
    for j in 1:length(visited)
        R[i,j]= visited[j] in neighbour(visited[i]) ? 0 : -Inf
    end
end

for i in 1:length(visited)
    j=findall(x->x==finalState,visited)
    R[i,j[1]]=100
end

function learnQ(R,gamma=0.8,alpha=1.0,nsims=100000)
    Q=zeros(size(R))
    states=length(visited)
    for i in 1:nsims
        k=rand(randomStrat)
        state=visited[k]
        new_state=rand(neighbour(state))
        j=findall(x->x==new_state,visited)[1]
        V=findmax(Q[j,:])[1]
        Q[k,j]=(1-alpha)*Q[k,j]+alpha*(R[k,j]+gamma*V)
    end
    if findmax(Q)[1]>0
        Q=Q/findmax(Q)[1]
    end
    return Q
end

function get_policy(Q)
    nstates=length(visited)
    policy=zeros(nstates)
    for i in 1:nstates
        policy[i]=findmax(Q[i,:])[2]
    end

    return policy
end