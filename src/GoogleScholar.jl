module GoogleScholar

using HTTP
using Plots
using PlotlyJS

export
    Scholar,
    get_citation_history!,
    plot_citations,
    bettersavefig

include("scholar.jl")
include("plots.jl")

end # module GoogleScholar
