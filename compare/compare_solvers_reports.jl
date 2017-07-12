using Plots
plotlyjs()


function total_time(dic; names = dic["names"])
  plt = Plots.plot(title = "Total Time Distribution")
  for name in names
      Plots.plot!(sort(dic["$(name)_tot"]), label=name)
  end
  display(plt)
  return plt
end

function total_time_nnz(dic; names = dic["names"])
  plt = Plots.plot(title = "(Total Time / Edges) Distribution")
  for name in names
      Plots.plot!(sort(dic["$(name)_tot"] ./ dic["ne"]), label=name)
  end
  display(plt)
  return plt
end



"""
    Given the list of solvers that were used, and a dic containing the results.
    Plot some graphs explaining how it went.
"""
function plots_and_stats(solvers,dic)

  plots_and_stats_raw(solvers,dic,"tot","Total Time")
  plots_and_stats_raw(solvers,dic,"build","Build Time")
  plots_and_stats_raw(solvers,dic,"solve","Solve Time")
  plots_and_stats_raw(solvers,dic,"its","Iterations")

end


function plots_and_stats(dic)

  plots_and_stats_raw(dic,"tot","Total Time")
  plots_and_stats_raw(dic,"build","Build Time")
  plots_and_stats_raw(dic,"solve","Solve Time")
  plots_and_stats_raw(dic,"its","Iterations")

end

function plot_relative(dic)

  plot_relative(dic,"tot","Total Time")
  plot_relative(dic,"build","Build Time")
  plot_relative(dic,"solve","Solve Time")
  plot_relative(dic,"its","Iterations")

end

function vec_stats(v)
    v = sort(v)
    n = length(v)
    print("mean: ",round(mean(v),3))
    pts = round(Int, [1, n/4, n/2, 3n/4, n])
    print(" quarts: ", v[pts])
    println()
end

function vec_stats(v,cnt)
    v = sort(v)
    n = length(v)
    print("mean: ",round(mean(v),3))
    pts = round(Int, [1, n/4, n/2, 3n/4, n])
    print(" quarts: ", v[pts])

    print("  (Inf: ",sum(isinf(cnt)), ")")

    println()
end

function plots_and_stats_raw(solvers,dic,str,title)

  plt = Plots.plot(title = title)
  sol1 = solvers[1]
  p = sortperm(dic["$(sol1.name)_$(str)"])
  for solver in solvers
      Plots.plot!(dic["$(solver.name)_$(str)"][p], label=solver.name)
  end
  display(plt)
end

function plots_and_stats_raw(dic,str,title)

  plt = Plots.plot(title = title)
    sol1 = dic["names"][1]
    key = "$(sol1)_$(str)"
    p = sortperm(dic[key])

    baserow = dic["$(sol1)_$(str)"][p]

    for name in dic["names"]
        key = "$(name)_$(str)"
        thisrow = dic[key][p]
        threshrow = min(thisrow, 10*baserow)
        Plots.plot!(threshrow, label=name)

        print(key, " ")
        vec_stats(threshrow, thisrow)
  end
  display(plt)
end



function plot_relative(dic,str,title)

  plt = Plots.plot(title = title)
    sol1 = dic["names"][1]
    key = "$(sol1)_$(str)"

    baserow = dic["$(sol1)_$(str)"]

    for i in 2:length(dic["names"])
        name = dic["names"][i]
        rowname = "$name / $(sol1)"
        key = "$(name)_$(str)"
        thisrow = dic[key]
        threshrow = min(thisrow, 10*baserow) ./ baserow
        Plots.plot!(sort(threshrow), label=rowname)

        print(str, " " ,rowname, " ")
        vec_stats(threshrow, thisrow)
  end
  display(plt)
end

function compare_two(dic,sol1,sol2)

  plt = Plots.plot(title = "Total Time, Relative")
    key1 = "$(sol1)_tot"
    key2 = "$(sol2)_tot"

    tot1 = dic[key1]
    tot2 = dic[key2]

    Plots.plot!(sort(tot1./tot2), label="$(sol1) / $(sol2)")
    Plots.plot!(sort(tot2./tot1), label="$(sol2) / $(sol1)")

  display(plt)

  plt = Plots.plot(title = "Total Time / nnz")
    key1 = "$(sol1)_tot"
    key2 = "$(sol2)_tot"

    tot1 = dic[key1]
    tot2 = dic[key2]
    ne = dic["ne"]

    Plots.plot!(sort(tot1./ne), label="$(sol1) / nnz")
    Plots.plot!(sort(tot2./ne), label="$(sol2) / nnz")

  display(plt)
end

"""
    sd = mask_dict(mcf,mask)

For example:
```
mask = mask = mcf["nv"] .> 20000
@show sum(mask)
sd = mask_dict(mcf,mask)
```
"""
function mask_dict(dic,mask)
    sol = dic["names"][1]
    ntests = length(dic["$(sol)_tot"])    
    
    subdict = Dict()

    for (key, value) in dic
        if length(dic[key]) == ntests
            subdict[key] = dic[key][mask]
        else
            subdict[key] = dic[key]
        end
    end
    return subdict
end
