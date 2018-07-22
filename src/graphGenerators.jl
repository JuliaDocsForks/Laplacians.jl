

import Random.randperm

"""
    ijv = empty_graph_ijv(n)
"""
empty_graph_ijv(n::Integer) = IJV{Float64,Int64}(Int64(n),0,[],[],[])

"""
    ijv = empty_graph(n)
"""
empty_graph(n::Integer) = sparse(empty_graph_ijv(n))


"""
    graph = path_graph(n)
"""
path_graph(n) = sparse(path_graph_ijv(n))

"""
    ijv = path_graph_ijv(n::Int64)
"""
function path_graph_ijv(n::Integer)
    IJV(n, 2*(n-1),
        [collect(1:(n-1)) ; collect(2:n)], 
        [collect(2:n); collect(1:(n-1))], 
        ones(2*(n-1)))
end


"""
    graph = complete_graph(n)
"""
function complete_graph(n::Integer)
  return sparse(ones(n,n) - Matrix(I,n,n))
end 

"""
    ijv = complete_graph_ijv(n)
"""
complete_graph_ijv(n::Integer) = IJV(complete_graph(n))


"""
    graph = ring_graph(n)
"""
ring_graph(n) = sparse(ring_graph_ijv(n))


"""
    ijv = ring_graph_ijv(n)
"""
function ring_graph_ijv(n::Integer)
    if n == 1
        return empty_graph_ijv(1)
    else
        return IJV(n, 2*n,
        [collect(1:(n-1)) ; collect(2:n); 1; n], 
        [collect(2:n); collect(1:(n-1)); n; 1], 
        ones(2*n))
    end
end    


"""
    graph = generalized_ring(n, gens)

A generalization of a ring graph.
The vertices are integers modulo n.
Two are connected if their difference is in gens.
For example,

```
generalized_ring(17, [1 5])
```
"""
generalized_ring(n::T, gens::Array{T}) where T <: Integer = 
    sparse(generalized_ring_ijv(n, gens))

function generalized_ring_ijv(n::T, gens::Array{T}) where T <: Integer
    gens = gens[mod.(gens, n) .> 0]
    if isempty(gens)
        return empty_graph_ijv(n)
    end

    k = length(gens)
    m = 2*n*k
    ai = zeros(Int64,m)
    aj = zeros(Int64,m)
    ind = 1
    for i in 0:(n-1)
        for j in 1:k
            ai[ind] = i
            aj[ind] = mod(i+gens[j],n)
            ind = ind + 1
            ai[ind] = i
            aj[ind] = mod(i-gens[j],n)
            ind = ind + 1
        end
    end
    return IJV(n, m, 1 .+ ai,1 .+ aj,ones(m))
end

"""
    graph = rand_gen_ring(n, k)

A random generalized ring graph of degree k.
Gens always contains 1, and the other k-1 edge types
are chosen from an exponential distribution
"""
rand_gen_ring(n::Integer, k::Integer; verbose=false) =
    sparse(rand_gen_ring_ijv(n,k,verbose=verbose))

function rand_gen_ring_ijv(n::Integer, k::Integer; verbose=false)

    # if any of n, 2n, 3n etc. is in gens we will have self loops
    gens = [0]
    while 0 in (gens .% n)
        gens = [1; 1 .+ ceil.(Integer,exp.(rand(k-1)*log(n-1)))]
    end

    if verbose
        println("gens: $(gens)")
    end            
    return generalized_ring_ijv(n, gens)
end



"""
    graph = hyperCube(d::Int64)

The d dimensional hypercube.  Has 2^d vertices and d*2^(d-1) edges.
"""
hypercube(d::Integer) = sparse(hypercube_ijv(d))

function hypercube_ijv(d::Integer)
    @assert d >= 0

    if d == 0
        return empty_graph_ijv(1)
    end

    ijvm = hypercube_ijv(d-1)

    ijv = disjoin(ijvm, ijvm)
    append!(ijv.i, [collect(1:2^(d-1)); 2^(d-1) .+ collect(1:2^(d-1))]  )
    append!(ijv.j, [2^(d-1) .+ collect(1:2^(d-1)); collect(1:2^(d-1))] )
    append!(ijv.v, ones(2^d))
    ijv.nnz += 2^d

    return ijv

end


"""
    graph = completeBinaryTree(n::Int64)

The complete binary tree on n vertices
"""
complete_binary_tree(n::Integer) = sparse(cbt_ijv(n))

function cbt_ijv(n::Integer)
    
    k = div(n-1,2)

    if 2*k+1 < n
        ii0 = Int[n-1]
        jj0 = Int[n]
    else
        ii0 = Int[]
        jj0 = Int[]
    end

    ii = [collect(1:k); collect(1:k); ii0]
    jj = [2*collect(1:k); 2*collect(1:k) .+ 1; jj0]

    return IJV(n, 2*(n-1),
        [ii;jj], [jj;ii], ones(2*length(ii)))

end

"""
    graph = grid2(n::Int64, m::Int64; isotropy=1)

An n-by-m grid graph.  iostropy is the weighting on edges in one direction.
"""
grid2(n::Integer, m::Integer; isotropy=1.0) = 
    sparse(grid2_ijv(n, m; isotropy=isotropy))

grid2_ijv(n::Integer, m::Integer; isotropy=1.0) =
    product_graph(isotropy*path_graph_ijv(n), path_graph_ijv(m))

grid2(n::Integer) = grid2(n,n)
grid2_ijv(n::Integer) = grid2_ijv(n,n)

"""
    graph = grid3(n1, n2, n3)
    graph = grid3(n)

An n1-by-n2-by-n3 grid graph.
"""
grid3(n1::Integer, n2::Integer, n3::Integer) = 
    sparse(grid3_ijv(n1, n2, n3))

grid3_ijv(n1::Integer, n2::Integer, n3::Integer) =
    product_graph(path_graph(n1), product_graph(path_graph(n2), path_graph(n3)))

grid3(n) = grid3(n,n,n)
grid3_ijv(n) = grid3_ijv(n,n,n)

"""
    graph = wGrid2(n::Integer; weightGen::Function=rand)

An n by n grid with random weights. User can specify the weighting scheme.
"""
wgrid2(n::Integer; weightGen::Function=rand) = 
    sparse(wgrid2_ijv(n, weightGen = weightGen))

function wgrid2_ijv(n::Integer; weightGen::Function=rand)
    gr2 = compress(grid2_ijv(n))

    # inefficient for backwards compatibility
    for i in 1:gr2.nnz
        gr2.v[i] = weightGen()
        if gr2.i[i] < gr2.j[i]
            gr2.v[i] = 0
        end
    end

    return compress(gr2 + gr2')

end


"""
    graph = grid2coords(n::Int64, m::Int64)
    graph = grid2coords(n::Int64)

Coordinates for plotting the vertices of the n-by-m grid graph
"""
function grid2coords(n::Int64, m::Int64)
  x = kron(collect(1:n),ones(m))
  y = kron(ones(n),collect(1:m))
  return x, y
end # grid2coords

grid2coords(n) = grid2coords(n, n)


"""
    graph = randMatching(n::Integer)

A random matching on n vertices
"""
rand_matching(n::Integer) = sparse(rand_matching_ijv(n))

function rand_matching_ijv(n::Integer)

  p = randperm(n)
  n1 = convert(Int64,floor(n/2))
  n2 = 2*n1

  ii = p[1:n1] 
  jj = p[(n1+1):n2]

  return IJV(n, n2, 
    [ii;jj], [jj; ii], ones(n2))

end 

"""
    graph = randRegular(n, k)

A sum of k random matchings on n vertices
"""
rand_regular(n::Integer, k::Integer) = sparse(rand_regular_ijv(n, k))

function rand_regular_ijv(n::Integer, k::Integer)

    n1 = convert(Int64,floor(n/2))
    n2 = 2*n1

    ii = Array{Int64}(undef, n1*k)
    jj = Array{Int64}(undef, n1*k)

    ind = 0
    for i in 1:k
        p = randperm(n)   
        for j in 1:n1
            ind += 1
            ii[ind] = p[j]
            jj[ind] = p[n1+j]
        end
    end

    return IJV(n, k*n2,
        [ii;jj], [jj;ii], ones(k*n2))

end 


"""
    graph = grown_graph(n, k)

Create a graph on n vertices.
For each vertex, give it k edges to randomly chosen prior
vertices.
This is a variety of a preferential attachment graph.
"""
grown_graph(n::Integer, k::Integer) = sparse(grown_graph_ijv(n,k))


function grown_graph_ijv(n::Integer, k::Integer)
    ii = Int[]
    jj = Int[]

    for i = 1:k
        append!(ii, collect(2:n))
        append!(jj, ceil.(Integer,collect(1:n-1).*rand(n-1)))
    end

    return IJV(n, 2*k*(n-1),
        [ii;jj], [jj;ii], ones(2*k*(n-1)))
    
end # grownGraph

# used in grownGraphD
function randSet(n::Integer,k::Integer)
    if n == k
        return collect(1:n)
    elseif n < k
        error("n must be at least k")
    else

        s = sort(ceil.(Integer,n*rand(k)))
        good = (minimum(s[2:end]-s[1:(end-1)]) > 0)
        while good == false
            s = sort(ceil.(Integer,n*rand(k)))
            good = (minimum(s[2:end]-s[1:(end-1)]) > 0)
        end

        return s

    end
end

"""
    graph = grown_graph_d(n::Integer, k::Integer)

Like a grownGraph, but it forces the edges to all be distinct.
It starts out with a k+1 clique on the first k vertices
"""
grown_graph_d(n::Integer, k::Integer) = sparse(grown_graph_d_ijv(n::Integer, k::Integer))

function grown_graph_d_ijv(n::Integer, k::Integer)
    @assert n > k > 1

    u = zeros(Int64, k*(n-k-1))
    v = zeros(Int64, k*(n-k-1))

    for i in (k+2):n
        nb = randSet(i-1,k)
        u[(i-k-2)*k .+ collect(1:k)] .= i
        v[(i-k-2)*k .+ collect(1:k)] .= nb
    end

    ijv = IJV(n, 2*length(u),
        [u;v], [v;u], ones(2*length(u)))

    clique = complete_graph_ijv(k+1)
    clique.n = n

    return ijv + clique
end 

"""
    graph = pref_attach(n::Int64, k::Int64, p::Float64)

A preferential attachment graph in which each vertex has k edges to those
that come before.  These are chosen with probability p to be from a random vertex,
and with probability 1-p to come from the endpoint of a random edge.
It begins with a k-clique on the first k+1 vertices.
"""
pref_attach(n::Integer, k::Integer, p::Float64) = sparse(pref_attach_ijv(n,k,p))

function pref_attach_ijv(n::Integer, k::Integer, p::Float64)
    @assert n > k
    if n == (k+1)
        return complete_graph_ijv(n)
    end

    u = zeros(Int64,n*k)
    v = zeros(Int64,n*k)


    # fill in the initial clique
    # this will accidentally double every edge in the clique
    # we clean it up at the end
    ind = 1
    for i in 1:(k+1)
        for j in 1:(k+1)
            if i != j
                u[ind] = i
                v[ind] = j
                ind += 1
            end
        end
    end

    s = zeros(Int64,k)
    for i in (k+2):n
        distinct = false
        while distinct == false
            for j in 1:k
                if rand(Float64) < p
                    s[j] = rand(1:(i-1))
                else
                    s[j] = v[rand(1:(k*(i-1)))]
                end
            end
            s = sort(s)
            distinct = true
            for ii in 1:(k-1)
                if s[ii] == s[ii+1]
                    distinct = false
                end
            end
            # distinct = (minimum(s[2:end]-s[1:(end-1)]) > 0)

        end

        for j in 1:k
            u[ind] = i
            v[ind] = s[j]
            ind += 1
        end

    end # for i

    w = ones(Float64,n*k)

    w[1:(k*(k+1))] .= 0.5

    return IJV(n, length(w),
        [u;v], [v;u], [w;w])

end


"""
    graph = randperm(mat::AbstractMatrix)
            randperm(f::Expr)

Randomly permutes the vertex indices
"""
function randperm(mat::AbstractMatrix)
    perm = randperm(mat.n)
    return mat[perm,perm]
end

function randperm(a::IJV)
    perm = randperm(a.n)
    return IJV(a.n, a.nnz,
        a.i[perm], a.j[perm], a.v[perm])
end   

randperm(f::Expr) = randperm(eval(f))


"""
    graph = ErdosRenyi(n::Integer, m::Integer)

Generate a random graph on n vertices with m edges.
The actual number of edges will probably be smaller, as we sample
with replacement
"""
function ErdosRenyi(n::Integer, m::Integer)
    ai = rand(1:n, m)
    aj = rand(1:n, m)
    ind = (ai .!= aj)

    mat = sparse(ai[ind],aj[ind],1.0,n,n)
    mat = mat + mat'
    unweight!(mat)
    return mat
end

ErdosRenyi_ijv(n::Integer, m::Integer) = IJV(ErdosRenyi(n::Integer, m::Integer))


"""
    graph = ErdosRenyiCluster(n::Integer, k::Integer)

Generate an ER graph with average degree k,
and then return the largest component.
Will probably have fewer than n vertices.
If you want to add a tree to bring it back to n,
try ErdosRenyiClusterFix.
"""
function ErdosRenyiCluster(n::Integer, k::Integer)
    m = ceil(Integer,n*k/2)
    ai = rand(1:n, m)
    aj = rand(1:n, m)
    ind = (ai .!= aj)
    mat = sparse(ai[ind],aj[ind],1.0,n,n)
    mat = mat + mat'

    return biggestComp(mat)
end

ErdosRenyiCluster_ijv(n::Integer, k::Integer) = IJV(ErdosRenyiCluster(n, k))

"""
    graph = ErdosRenyiClusterFix(n::Integer, k::Integer)

Like an Erdos-Renyi cluster, but add back a tree so
it has n vertices
"""
function ErdosRenyiClusterFix(n::Integer, k::Integer)
    m1 = ErdosRenyiCluster(n, k)
    n2 = n - size(m1)[1]
    if (n2 > 0)
        m2 = completeBinaryTree(n2)
        return joinGraphs(m1,m2,1)
    else
        return m1
    end
end

function ErdosRenyiClusterFix_ijv(n::Integer, k::Integer)
    m1 = ErdosRenyiCluster_ijv(n, k)
    n2 = n - m1.n
    if (n2 > 0)
        m2 = cbt_ijv(n2)
        join_graphs!(m1,m2,1)
    end

    return m1

end

"""
    graph = pureRandomGraph(n::Integer; verbose=false)

Generate a random graph with n vertices from one of our natural distributions
"""
function pureRandomGraph(n::Integer; verbose=false, prefix="")

    gr = []
    wt = []

    push!(gr,:(pathGraph($n)))
    push!(wt,1)

    push!(gr,:(ringGraph($n)))
    push!(wt,3)

    push!(gr,:(completeBinaryTree($n)))
    push!(wt,3)

    push!(gr,:(grownGraph($n,2)))
    push!(wt,6)

    push!(gr,:(grid2(ceil(Integer,sqrt($n)))[1:$n,1:$n]))
    push!(wt,6)

    push!(gr,:(randRegular($n,3)))
    push!(wt,6)

    push!(gr,:(ErdosRenyiClusterFix($n,2)))
    push!(wt,6)

    if n >= 4
        push!(gr,:(randGenRing($n,4,verbose=$(verbose))))
        push!(wt,6)
    end

    i = sampleByWeight(wt)

    # make sure get a connected graph
    its = 0
    mat = eval(gr[i])
    if verbose
        println(prefix, gr[i])
    end


    while (~isConnected(mat)) && (its < 100)
        i = sampleByWeight(wt)

        mat = eval(gr[i])
        its += 1
    end
    if its == 100
        error("Getting a disconnected graph from $(gr[i])")
    end

    if (sum(diag(mat)) > 0)
        error("nonzero diag from $(gr[i])")
    end


    return floatGraph(mat)

end

pure_random_graph(n::Integer; verbose=false, prefix="") = 
    sparse(pure_random_ijv(n; verbose=verbose, prefix=prefix))

function pure_random_ijv_v6(n::Integer; verbose=false, prefix="")

    gr = []
    wt = []

    push!(gr,:(path_graph_ijv($n)))
    push!(wt,1)

    push!(gr,:(ring_graph_ijv($n)))
    push!(wt,3)

    push!(gr,:(cbt_ijv($n)))
    push!(wt,3)

    push!(gr,:(grown_graph_ijv($n,2)))
    push!(wt,6)

    push!(gr,:(firstn(grid2_ijv(ceil(Integer,sqrt($n))), $n)))
    push!(wt,6)

    push!(gr,:(rand_regular_ijv($n,3)))
    push!(wt,6)

    push!(gr,:(ErdosRenyiClusterFix_ijv($n,2)))
    push!(wt,6)

    if n >= 4
        push!(gr,:(rand_gen_ring($n,4,verbose=$(verbose))))
        push!(wt,6)
    end

    i = sampleByWeight(wt)

    # make sure get a connected graph - will want to remove.
    if verbose
        println(prefix, gr[i])
    end
    ijv = eval(gr[i])

    its = 0
    while (~isConnected(sparse(ijv))) && (its < 100)
        i = sampleByWeight(wt)

        ijv = eval(gr[i])
        its += 1
    end
    if its == 100
        error("Getting a disconnected graph from $(gr[i])")
    end

    return ijv

end

"""
    a = pure_random_ijv(n::Integer; verbose=false, prefix="")

Chooses among path_graph, ring_graph, grid_graph, complete_binary_tree, rand_gen_ring, grown_graph and ErdosRenyiClusterFix.
It can produce a disconnected graph.
For code that always produces a connected graph (and is the same as with Julia v0.6, use pure_random_ijv_v6)
"""
function pure_random_ijv(n::Integer; verbose=false, prefix="")

    n >= 4 ? rmax = 37 : rmax = 31

    r = rmax*rand()

    if r <= 1
        ijv = path_graph_ijv(n)
        verbose && println("$(prefix) path_graph($(n))")

    elseif r <= 4
        ijv = ring_graph_ijv(n)
        verbose && println("$(prefix) ring_graph($(n))")

    elseif r <= 7
        ijv = cbt_ijv(n)
        verbose && println("$(prefix) complete_binary_tree($(n))")

    elseif r <= 13
        ijv = grown_graph_ijv(n,2)
        verbose && println("$(prefix) grown_graph($(n))")

    elseif r <= 19
        ijv = firstn(grid2_ijv(ceil(Integer,sqrt(n))), n)
        verbose && println("$(prefix) firstn_grid2($(n))")

    elseif r <= 25
        ijv = rand_regular_ijv(n,3)
        verbose && println("$(prefix) rand_regular_ijv($(n),3)")

    elseif r <= 31
        ijv = ErdosRenyiClusterFix_ijv(n,2)
        verbose && println("$(prefix) ErdosRenyiClusterFix_ijv($n,2)")

    else
        ijv = rand_gen_ring(n,4, verbose=verbose)   
        verbose && println("$(prefix) rand_gen_ring($(n), 4)")   
                

    end

    return ijv

end

"""
    ind = sampleByWeight(wt)

sample an index with probability proportional to its weight given here
"""
function sampleByWeight(wt)
    r = rand(1)*sum(wt)
    findall(cumsum(wt) .> r)[1]
end

"""
    graph = semiWtedChimera(n::Integer; verbose=false)

A Chimera graph with some weights.  The weights just appear when graphs are combined.
For more interesting weights, use `wtedChimera`
"""
function semiWtedChimera(n::Integer; verbose=false, prefix="")

    if (n < 2)
        return spzeros(1,1)
    end

    r = rand()^2

    if (n < 30) || (rand() < .2)

        gr = pureRandomGraph(n, verbose=verbose, prefix=prefix)

        return randperm(gr)
    end

    if (n < 200)
        # just join disjoint copies of graphs

        n1 = 10 + floor(Integer,(n-20)*rand())
        n2 = n - n1
        k = ceil(Integer,exp(rand()*log(min(n1,n2)/2)))

        if verbose
            println(prefix,"joinGraphs($(r)*chimera($(n1)),chimera($(n2)),$(k))")
        end

        pr = string(" ",prefix)
        gr = joinGraphs(r*chimera(n1;verbose=verbose,prefix=pr),
          chimera(n2;verbose=verbose,prefix=pr),k)

        return randperm(gr)
    end

    # split with probability .7

    if (rand() < .7)
        n1 = ceil(Integer,10*exp(rand()*log(n/20)))

        n2 = n - n1
        k = floor(Integer,1+exp(rand()*log(min(n1,n2)/2)))

        if verbose
            println(prefix,"joinGraphs($(r)*chimera($(n1)),chimera($(n2)),$(k))")
        end

        pr = string(" ",prefix)
        gr = joinGraphs(r*chimera(n1;verbose=verbose,prefix=pr),
          chimera(n2;verbose=verbose,prefix=pr),k)

        return randperm(gr)

    else
        n1 = floor(Integer,10*exp(rand()*log(n/100)))

        n2 = floor(Integer, n / n1)

        if (rand() < .5)

            if verbose
                println(prefix,"productGraph($(r)*chimera($(n1)),chimera($(n2)))")
            end
            pr = string(" ",prefix)
            gr = productGraph(r*chimera(n1;verbose=verbose,prefix=pr),
              chimera(n2;verbose=verbose,prefix=pr))

        else

            k = floor(Integer,1+exp(rand()*log(min(n1,n2)/10)))

            if verbose
                println(prefix, "generalizedNecklace($(r)*chimera($(n1)),chimera($(n2)),$(k))")
            end
            pr = string(" ",prefix)
            gr = generalizedNecklace(r*chimera(n1;verbose=verbose,prefix=pr),
              chimera(n2;verbose=verbose,prefix=pr),k)

        end

        n3 = n - size(gr)[1]
        if (n3 > 0)

            if verbose
                println(prefix, "joinGraphs(gr,chimera($(n3)),2)")
            end

            pr = string(" ",prefix)
            gr = joinGraphs(gr,chimera(n3;verbose=verbose,prefix=pr),2)

        end

        return randperm(gr)

    end
end


"""
    graph = chimera(n::Integer; verbose=false)

Builds a chimeric graph on n vertices.
The components come from pureRandomGraph,
connected by joinGraphs, productGraph and generalizedNecklace
"""
function chimera(n::Integer; verbose=false, prefix="")


    gr = semiWtedChimera(n; verbose=verbose, prefix=prefix)
    unweight!(gr)

    return gr

end

"""
    graph = chimera(n::Integer, k::Integer; verbose=false)

Builds the kth chimeric graph on n vertices.
It does this by resetting the random number generator seed.
It should captute the state of the generator before that and then
return it, but it does not yet.
"""
function chimera(n::Integer, k::Integer; verbose=false, prefix="")
    srand(100*n+k)
    g = chimera(n; verbose=verbose, prefix=prefix)
    return g
end

"""
    graph = randWeight(graph)

Applies one of a number of random weighting schemes to the edges of the graph
"""
function randWeight(a)

    if (rand() < .2)
        return a
    else
        return randWeightSub(a)
    end
end


function randWeightSub(a)

    n = a.n
    (ai,aj) = findnz(a)
    m = length(ai)

    # potentials or edge-based

    if (rand() < .3)
        w = rand(m)

    else
        v = randn(a.n)

        # mult by matrix ?
        if (rand() < .5)

            invdeg = sparse(Diagonal(1 ./(a*ones(size(a)[1]))))
            if (rand() < .5)
                for i in 1:10
                    v = a * (invdeg * v)
                    v = v .- mean(v)
                end
            else
                for i in 1:10
                    v = v - a * (invdeg * v)
                    v = v .- mean(v)
                end
            end
        end

        w = abs.(v[ai] - v[aj])

    end

    # reciprocate or not?

    w[w.==0] .= 1
    w[isnan.(w)] .= 1

    if (rand() < .5)
        w = 1 ./w
    end

    w = w / mean(w)

    ar = sparse(ai,aj,w,n,n)
    ar = ar + ar';
    return ar
end

"""
    graph = wtedChimera(n::Integer, k::Integer; verbose=false)

Builds the kth wted chimeric graph on n vertices.
It does this by resetting the random number generator seed.
It should captute the state of the generator before that and then
return it, but it does not yet.
"""
function wtedChimera(n::Integer, k::Integer; verbose=false)
    srand(100*n+k)
    g = wtedChimera(n; verbose=verbose)
    return g
end

function semiWtedChimera(n::Integer, k::Integer; verbose=false, prefix="")
    srand(100*n+k)
    g = semiWtedChimera(n; verbose=verbose, prefix=prefix)
    return g
end


"""
    graph = wtedChimera(n::Integer)

Generate a chimera, and then apply a random weighting scheme
"""
function wtedChimera(n::Integer; verbose=false)
    return randWeight(semiWtedChimera(n; verbose=verbose))
end
