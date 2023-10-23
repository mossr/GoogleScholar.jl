Base.@kwdef mutable struct Scholar
    user
    name = ""
    years = Int[]
    citations_per_year = Int[]
    total = 0
end

url(scholar::Scholar) = "https://scholar.google.com/citations?hl=en&user=$(scholar.user)&pagesize=100&view_op=list_works"

function get_html_element(element_tag, element_start_regex, element_end_regex, body; return_content=false, isnested=false)
    m = match(element_start_regex, body)
    if isnothing(m)
        @info "No HTML element that starts with: $(element_start_regex.pattern)"
        return return_content ? (nothing, nothing) : nothing
    end

    local element_end_range

    element_start_range = m.offset:length(m.captures[1])+m.offset-1
    i = element_start_range[end]+1

    if isnested
        # e.g., could be <div> elements inside of <div>
        open_elements = 1

        while open_elements > 0
            # traverse the nested divs to find the end </div>
            m_start_el = match(Regex("(<$(element_tag)[\\w\\-=\\\"\\d\\s;:]*>)"), body, i)
            m_end_el = match(element_end_regex, body, i)
    
            if m_start_el.offset < m_end_el.offset
                open_elements += 1
                i = m_start_el.offset + length(m_start_el.captures[1]) - 1
            else
                open_elements -= 1
                i = m_end_el.offset + length(m_end_el.captures[1]) - 1
            end
            element_end_range = m_end_el.offset:length(m_end_el.captures[1])+m_end_el.offset-1
        end
    else
        m_end_el = match(element_end_regex, body, i)
        element_end_range = m_end_el.offset:length(m_end_el.captures[1])+m_end_el.offset-1
    end

    if return_content
        remainder = body[element_end_range[end]+1:end]
        content = body[element_start_range[end]+1:element_end_range[1]-1]
        return content, remainder
    else
        html = body[element_start_range[1]:element_end_range[end]]
        return html
    end
end

function get_citation_history!(scholar::Scholar)
    r = HTTP.get(url(scholar))
    body = String(r.body)

    scholar.name, _ = get_html_element("div", r"(<div id=\"gsc_prf_in\">)", r"(</div>)", body; return_content=true)

    total_table = get_html_element("table", r"(<table id=\"gsc_rsb_st\">)", r"(</table>)", body)
    scholar.total = parse(Int, get_html_element("td", r"(<td class=\"gsc_rsb_std\">)", r"(</td>)", total_table; return_content=true)[1])

    div = get_html_element("div", r"(<div class=\"gsc_md_hist_w\">)", r"(</div>)", body; isnested=true)

    r_year = r"(<span class=\"gsc_g_t\"[\s\w=\":;]*>)"
    year, remainder = get_html_element("span", r_year, r"(</span>)", div; return_content=true)
    push!(scholar.years, parse(Int, year))

    while !isnothing(year)
        year, remainder = get_html_element("span", r_year, r"(</span>)", remainder; return_content=true)
        if !isnothing(year)
            push!(scholar.years, parse(Int, year))
        end
    end

    r_citations = r"(<span class=\"gsc_g_al\"[\s\w=\":;]*>)"
    citations, remainder = get_html_element("span", r_citations, r"(</span>)", div; return_content=true)
    push!(scholar.citations_per_year, parse(Int, citations))

    while !isnothing(citations)
        citations, remainder = get_html_element("span", r_citations, r"(</span>)", remainder; return_content=true)
        if !isnothing(citations)
            push!(scholar.citations_per_year, parse(Int, citations))
        end
    end

    return scholar
end
