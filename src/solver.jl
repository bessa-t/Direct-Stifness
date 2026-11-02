function solve_linear_system(K,U,F)
    elimination = vec()
    i=0
    for u in U
        i+=1
        if u ==0
            push!(elimination,i)
        end
    end
    for i in elimination
        F[i] = 0
        for row in K
            
    end

end