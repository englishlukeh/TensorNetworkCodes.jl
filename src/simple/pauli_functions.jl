"""
    pauli_commutation(a::Int, b::Int) -> 0 or 1
    pauli_commutation(a::AbstractVector{Int}, b::AbstractVector{Int}) -> 0 or 1

Return the commutation relation of two Paulis, i.e. 0 if they commute and 1 if not.

# Examples
```jldoctest
julia> pauli_commutation(1, 1)  # X commutes with itself
0

julia> pauli_commutation(1, 3)  # X does not commute with Z
1
```

```jldoctest
julia> pauli_commutation([1, 3, 3, 1, 0], [1, 1, 1, 1, 1])  # XZZXI commutes with XXXXX
0

julia> stabilizers = [[1, 3, 3, 1, 0], [0, 1, 3, 3, 1], [1, 0, 1, 3, 3], [3, 1, 0, 1, 3]];

julia> error = [1, 1, 0, 0, 0];  # XXIII

julia> syndrome = pauli_commutation.(stabilizers, Ref(error))
4-element Vector{Int64}:
 1
 0
 0
 1
```
"""
function pauli_commutation(a::Int, b::Int)
    if a == 0
        return 0
    elseif b == 0
        return 0
    elseif a == b
        return 0
    else
        return 1
    end
end
function pauli_commutation(a::AbstractVector{Int}, b::AbstractVector{Int})
    output = 0
    for n in 1:length(a)
        output += pauli_commutation(a[n], b[n])
    end
    return mod(output, 2)
end

"""
    pauli_product(a::Int, b::Int) -> Int

Return the product of two Paulis.

# Examples
```jldoctest
julia> pauli_product(1, 2) # X.Y -> Z
3

julia> pauli_product.([1,0,3,2], [1,1,1,3]) # (XIZY).(XXXZ) -> (IXYX)
4-element Vector{Int64}:
 0
 1
 2
 1
```
"""
function pauli_product(a::Int, b::Int)
    if a == 0
        return b
    elseif b == 0
        return a
    elseif a == b
        return 0
    else
        for n in 1:3
            if n != a && n != b
                return n
            end
        end
    end
end

"""
Third method: checks if a set of Pauli vectors is commuting (0) or not commuting (1).
"""
function do_they_commute(a::Array{Array{Int64,1},1})
    num_operators = length(a)
    for n in 1:num_operators, m in 1:n - 1
        if pauli_commutation(a[n], a[m]) == 1
            return 1
            break
        end
    end
    return 0
end





"""
    pauli_rep_change(pauli::Char) -> Int

Converts from alphabetical to numerical representation of Paulis.
"""
function pauli_rep_change(pauli::Char)
    if pauli ==  'I'
        return 0
    elseif pauli == 'x'
        return 1
    elseif pauli == 'y'
        return 2
    elseif pauli == 'z'
        return 3
    end
end



"""
    pauli_rep_change(pauli::Int) -> Char

Converts from numerical to alphabetical representation of Paulis.
"""
function pauli_rep_change(pauli::Int)
    if pauli == 0
        return 'I'
    elseif pauli == 1
        return 'x'
    elseif pauli == 2
        return 'y'
    elseif pauli == 3
        return 'z'
    end
end











"""
    product_with_powers(operators,powers) -> Array{Int64,1}

Give a list of operators and binary powers, this returns their
product with the appropriate powers.
"""
function product_with_powers(operators, powers)::Array{Int64,1}
    output = fill(0, length(operators[1]))
    for n in 1:length(operators)
        if powers[n] != 0
            if !(powers[n] in [0,1])
                error("powers of Paulis are not in [0,1]!")
            end
            output = pauli_product.(output, operators[n])
        end
    end
    return output
end

product_with_powers(g,l,powers) = product_with_powers(vcat(g, l), powers)





"""
Find the weight of a vector of Pauli operators, i.e., the number of entries with
non identity elements.
"""
function weight(operator)
    output = 0
    for n in 1:length(operator)
        if operator[n] != 0
            output += 1
        end
    end
    return output
end


"""
    are_they_independent(operators)

Checks if a set of Pauli vectors is independent, i.e., is any one a product of
the others.
"""
function are_they_independent(operators::Array{Array{Int64,1},1})

    num_operators = length(operators)
    num_qubits = length(operators[1])
    remaining = collect(1:num_operators)

    for qubit in 1:num_qubits
        paulis = [1,2,3]
        indices = Int[]
        for α in remaining
            if operators[α][qubit] in paulis
                setdiff!(paulis, operators[α][qubit])
                push!(indices, α)
            end
            if length(paulis) == 1
                break
            end
        end

        remaining = setdiff(remaining, indices)
        for α in remaining
            if operators[α][qubit] == 0
                continue
            end
            new_operator = pauli_product.(operators[α], operators[indices[1]])
            if new_operator[qubit] == 0
                operators[α] = deepcopy(new_operator)
                continue
            end
            if length(paulis) == 2
                continue
            end
            new_operator = pauli_product.(operators[α], operators[indices[2]])
            if new_operator[qubit] == 0
                operators[α] = deepcopy(new_operator)
                continue
            end
            new_operator = pauli_product.(operators[α], operators[indices[1]])
            new_operator = pauli_product.(new_operator, operators[indices[2]])
            if new_operator[qubit] == 0
                operators[α] = deepcopy(new_operator)
                continue
            end
        end

        for α in remaining
            if operators[α] == zeros(Int64, num_qubits)
                return false
            end
        end
    end

    return true

end
