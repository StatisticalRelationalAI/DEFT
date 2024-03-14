using OrderedCollections, Multisets

@isdefined(DiscreteFactor) || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(buckets)        || include(string(@__DIR__, "/buckets.jl"))

"""
	is_exchangeable_naive(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Check whether `f1` and `f2` are exchangeable.
The implementation naively tries all permutations of the arguments.
"""
function is_exchangeable_naive(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	length(rvs(f1)) != length(rvs(f2)) && return false
	f1_copy = deepcopy(f1)
	f2_copy = deepcopy(f2)
	return permute_args!(f1_copy, f2_copy)
end

"""
	is_exchangeable_filter(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Check whether `f1` and `f2` are exchangeable.
The implementation uses the buckets of the factors to enforce the necessary
condition that both factors must have identical buckets.
"""
function is_exchangeable_filter(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	if length(rvs(f1)) != length(rvs(f2)) || buckets(f1) != buckets(f2)
		return false
	end
	f1_copy = deepcopy(f1)
	f2_copy = deepcopy(f2)
	return permute_args!(f1_copy, f2_copy)
end

"""
	is_exchangeable_deft(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Check whether `f1` and `f2` are exchangeable.
The implementation applies the DEFT algorithm to check whether the factors
are exchangeable, i.e., buckets are used both as a necessary and sufficient
condition.
"""
function is_exchangeable_deft(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	length(rvs(f1)) != length(rvs(f2)) && return false
	f1_copy = deepcopy(f1)
	f2_copy = deepcopy(f2)
	return validate_buckets!(f1_copy, f2_copy)
end

"""
	validate_buckets!(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Check whether `f1` and `f2` are exchangeable and if so, permute the arguments
of `f2` such that the tables of potential mappings of `f1` and `f2` are
identical.
"""
function validate_buckets!(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	buckets_f1, confs_f1 = buckets_ordered(f1, false)
	buckets_f2, confs_f2 = buckets_ordered(f2, true)

	# Possible swaps over the whole factor
	factor_set = Dict{Int, Set{Int}}()
	# Iterate all buckets to obtain positions of values that can be swapped
	# (in order of ascending degree of freedom)
	bucket_counter = 0
	for (bucket, bucketvalues) in buckets_f2
		vals = Multiset(bucketvalues)
		# Buckets contain different values
		vals != Multiset(buckets_f1[bucket]) && return false
		if vals[first(vals)] == length(vals)
			# All values identical, so all positions are possible
			bucket_set = Dict{Int, Set{Int}}(
				i => Set([j for j in 1:length(rvs(f2))]) for i in 1:length(rvs(f2))
			)
		else
			# Possible swaps over the current bucket
			bucket_set = Dict{Int, Set{Int}}()
			for (index, item) in enumerate(bucketvalues)
				# Possible swaps over the current item
				item_set = Dict{Int, Set{Int}}()
				# Row (assignment of arguments) of the current item in the table
				item_row = confs_f2[bucket][index]
				# Indices in other bucket where the current item is present
				index_in_other = findall(x -> x == item, buckets_f1[bucket])
				for o_index in index_in_other
					other_row = confs_f2[bucket][o_index]
					positions = valuepositions(other_row)
					# Insert all possible swaps for the current item
					for (pos, value) in enumerate(item_row)
						for el in positions[value]
							!haskey(item_set, pos) && (item_set[pos] = Set{Int}())
							push!(item_set[pos], el)
						end
					end
				end

				if all(isempty, values(bucket_set))
					bucket_set = item_set
				else
					!build_intersection!(bucket_set, item_set) && return false
				end
			end
		end

		if all(isempty, values(factor_set))
			factor_set = bucket_set
		else
			!build_intersection!(factor_set, bucket_set) && return false
		end

		# Comment out to loop over all buckets instead of applying heuristic
		bucket_counter += 1
		bucket_counter >= 5 && break
	end

	function do_swaps!(curr_swap::Dict{Int, Int}, poss_swaps::Dict{Int, Set{Int}})::Bool
		if isempty(poss_swaps) # Leave node, i.e., positions are fixed
			@debug "Apply swap rules: $curr_swap"
			vals = values(curr_swap)
			# Multiple vars are assigned the same position
			length(unique(vals)) != length(vals) && return false
			f2_cpy = deepcopy(f2) # Access f2 from outer scope
			apply_swap_rules!(f2_cpy, curr_swap)
			return is_swap_successful(f1, f2_cpy)
		else # Not all positions have been fixed yet, so recurse further
			poss_swaps_cpy = deepcopy(poss_swaps)
			position, swaps = pop!(poss_swaps_cpy)

			for other_pos in swaps
				# Position already used
				!(other_pos in values(curr_swap)) || continue
				curr_swap[position] = other_pos
				do_swaps!(curr_swap, poss_swaps_cpy) && return true
				delete!(curr_swap, position)
			end

			return false # Nothing found for all possible swaps
		end
	end

	@debug "Finished computing possible swaps: $factor_set"
	return do_swaps!(Dict{Int, Int}(), factor_set)
end

"""
	build_intersection!(set1::Dict{Int, Set{Int}}, set2::Dict{Int, Set{Int}})::Bool

Build the intersection of the sets in `set1` and `set2`.
Return `false` if there is an empty intersection for any of the sets, else
return `true`.
"""
function build_intersection!(set1::Dict{Int, Set{Int}}, set2::Dict{Int, Set{Int}})::Bool
	for key in keys(set1)
		set1[key] = intersect(set1[key], set2[key])
		isempty(set1[key]) && return false
	end
	return true
end

"""
	apply_swap_rules!(f::DiscreteFactor, swap_rules::Dict{Int, Int})

Apply the given swap rules to the factor `f`.
`swap_rules` is a dictionary that maps each position to a new position.
"""
function apply_swap_rules!(f::DiscreteFactor, swap_rules::Dict{Int, Int})
	permutation = [i for i in 1:length(rvs(f))]
	for key in keys(swap_rules)
		permutation[swap_rules[key]] = key
	end
	@debug "New argument order: $permutation"
	new_potentials = Dict()
	for c in collect(Base.Iterators.product(map(x -> range(x), f.rvs)...))
		new_c = collect(c)
		new_c = [new_c[i] for i in permutation]
		new_potentials[join(new_c, ",")] = potential(f, collect(c))
	end
	f.potentials = new_potentials
	f.rvs = [f.rvs[i] for i in permutation]
end

"""
	is_swap_successful(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Check whether the swap of arguments in `f2` is successful, i.e., the tables of
potential mappings of `f1` and `f2` are identical.
Assumes that `f1` and `f2` are defined over the same configuration space.
"""
function is_swap_successful(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	# Assumption: map(x -> range(x), rvs(f1)) == map(x -> range(x), rvs(f2))
	for c in Base.Iterators.product(map(x -> range(x), rvs(f1))...)
		conf = collect(c)
		potential(f1, conf) != potential(f2, conf) && return false
	end
	return true
end