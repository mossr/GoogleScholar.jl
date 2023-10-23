default(
    fontfamily="Palatino Roman",
    framestyle=:axes,
    legend=:bottomright,
    linewidth=2,
    titlefont=15,
    legendfontsize=14,
    guidefontsize=14,
    tickfontsize=8,
    colorbartickfontsizes=14,
    xgrid=false,
    ygrid=true,
    widen=false,
)

function plot_citations(scholar::Scholar; color="#777777", use_plotly=false)
    if use_plotly
        plotlyjs()
        plt = Plots.plot(
            topmargin=5Plots.mm,
            bottommargin=5Plots.mm,
            leftmargin=0Plots.mm,
            rightmargin=12Plots.mm,
            size=(600, 150),
        )
    else
        gr()
        plt = Plots.plot(
            topmargin=5Plots.mm,
            bottommargin=5Plots.mm,
            leftmargin=5Plots.mm,
            rightmargin=5Plots.mm,
            size=(500, 250),
        )
    end

    Plots.bar!(scholar.years, scholar.citations_per_year;
        bar_width=0.4,
        color,
        linecolor=nothing,
        label=false,
        xtick=scholar.years,
        y_foreground_color_border=:white,
        y_foreground_color_axis=:white,
        y_foreground_color_text=color,
        y_guidefontcolor=color,
        x_foreground_color_border=:white,
        x_foreground_color_axis=color,
        x_foreground_color_text=color,
        x_guidefontcolor=color,
        ymirror=true,
        ylabel="citations")
    yl = ylims()
    ylims!(yl[1], yl[2]*1.1)
    return plt
end

bettersavefig(filename; kwargs...) = bettersavefig(plot!(), filename; kwargs...)

function bettersavefig(fig, filename; dpi=300, save_svg=false)
    filename_png = "$filename.png"
    filename_svg = "$filename.svg"
    Plots.savefig(fig, filename_svg)
    try
        if Sys.iswindows()
            # run(`inkscape -f $filename_svg -e $filename_png -d $dpi`) # old Windows inkscape.exe
            run(`inkscapecom $filename_svg --export-filename=$filename_png -d $dpi`)
        else
            run(`inkscape $filename_svg -o $filename_png -d $dpi`)
        end
    catch err
        @warn "If inkscape is not installed, try running: sudo apt install inkscape"
        error(err)
    end
    if !save_svg
        rm(filename_svg)
    end
end
