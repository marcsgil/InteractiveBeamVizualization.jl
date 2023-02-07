module InteractiveBeamVizualization

using GLMakie

export interactive_vizualization,produce_animation

function interactive_vizualization(ψs::AbstractArray{T,3},xs,ys,zs;cmax=0) where T <: Number
    GLMakie.activate!()

    theme = Theme(fontsize = 30)
    set_theme!(theme)
    fig = Figure()
    ax = Axis(fig[1, 1],aspect=1)

    intensities = T <: Real ? ψs : abs2.(ψs)

    xlims!(first(xs),last(xs))
    ylims!(first(ys),last(ys))
    sl = Slider(fig[2, 1], range = axes(ψs,3), startvalue = 1)

    current_result = lift(n->view(intensities,:,:,n),sl.value)

    current_title = lift(sl.value) do n
        ax.title = "z = $(round(zs[n],digits=2))"
    end

    if iszero(cmax)
        heatmap!(fig[1,1],xs,ys,current_result,colormap=:hot)
    else
        hm = heatmap!(fig[1,1],xs,ys,current_result,colormap=:hot,colorrange=(0,cmax))
        Colorbar(fig[:, end+1],hm)
    end
    fig
end

function interactive_vizualization(ψs::AbstractArray{T,4},xs,ys,zs;csmax) where T <: Number
    GLMakie.activate!()

    @assert length(csmax) == size(ψs,4) "The length of csmax doesn't match the number of beams given."

    theme = Theme(fontsize = 30)
    set_theme!(theme)
    fig = Figure()

    not_zero_pos = findall(iszero |> !,csmax)

    has_heatmap = trues(size(ψs,4) + length(not_zero_pos))

    counter = 1
    for i in eachindex(csmax)
        if i ∈ not_zero_pos
            has_heatmap[counter+1] = false
            counter += 2
        else
            counter += 1
        end
    end

    heatmap_pos = findall(has_heatmap)
    colorbar_pos = findall(!,has_heatmap)

    heatmap_pos,colorbar_pos
    
    axs = [Axis(fig[1, n],aspect=1) for n in heatmap_pos]

    intensities = T <: Real ? ψs : abs2.(ψs)
    
    xlims!(first(xs),last(xs))
    ylims!(first(ys),last(ys))
    sl = Slider(fig[2, :], range = axes(ψs,3), startvalue = 1)

    current_Is = [lift(n->view(intensities,:,:,n,m),sl.value) for m in axes(ψs,4)]
    
    title = Label(fig[0, :], L"z = %$(round(zs[1],digits=2))", fontsize = 30)
    lift(sl.value) do n
        title.text = L"z = %$(round(zs[n],digits=2))"
    end
    
    counter = 1
    for i in eachindex(csmax)
        if i ∈ not_zero_pos
            hm = heatmap!(fig[1,counter],xs,ys,current_Is[i],colormap=:hot,colorrange=(0,csmax[i]))
            Colorbar(fig[1, counter+1], hm) 
            counter += 2
        else
            heatmap!(fig[1,counter],xs,ys,current_Is[i],colormap=:hot)
            counter += 1
        end
    end

    fig
end

function produce_animation(ψs::AbstractArray{T,4},xs,ys,zs,filename,framerate;csmax) where T <: Number
    GLMakie.activate!()

    @assert length(csmax) == size(ψs,4) "The length of csmax doesn't match the number of beams given."

    theme = Theme(fontsize = 30)
    set_theme!(theme)
    fig = Figure(resolution = (1650, 650))

    not_zero_pos = findall(iszero |> !,csmax)

    has_heatmap = trues(size(ψs,4) + length(not_zero_pos))

    counter = 1
    for i in eachindex(csmax)
        if i ∈ not_zero_pos
            has_heatmap[counter+1] = false
            counter += 2
        else
            counter += 1
        end
    end

    heatmap_pos = findall(has_heatmap)
    colorbar_pos = findall(!,has_heatmap)

    titles = ["Gaussian","Gaussian","TGSM","TGSM"]
    
    axs = [Axis(fig[1, n],aspect=1, width = 600, height = 500,title=titles[n]) for n in heatmap_pos]

    intensities = T <: Real ? ψs : abs2.(ψs)
    
    xlims!(first(xs),last(xs))
    ylims!(first(ys),last(ys))
    
    title = Label(fig[0, :], L"z = %$(round(zs[1],digits=2))", fontsize = 30)
    
    counter = 1
    for i in eachindex(csmax)
        if i ∈ not_zero_pos
            hm = heatmap!(fig[1,counter],xs,ys,view(intensities,:,:,1,i),colormap=:hot,colorrange=(0,csmax[i]))
            Colorbar(fig[1, counter+1], hm) 
            counter += 2
        else
            heatmap!(fig[1,counter],xs,ys,view(intensities,:,:,1,i),colormap=:hot)
            counter += 1
        end
    end

    function update(n)
        title.text = L"z = %$(round(zs[n],digits=2))"

        counter = 1
        for i in eachindex(csmax)
            if i ∈ not_zero_pos
                hm = heatmap!(fig[1,counter],xs,ys,view(intensities,:,:,n,i),colormap=:hot,colorrange=(0,csmax[i]))
                counter += 2
            else
                heatmap!(fig[1,counter],xs,ys,view(intensities,:,:,n,i),colormap=:hot)
                Axis(fig[1,counter], width = 150, height = 150)
                counter += 1
            end
        end
    end

    GLMakie.record(update,fig, filename, 1:size(ψs,3); framerate = framerate)
end

end
