using Combinatorics, Multisets, OrderedCollections

@isdefined(DiscreteFactor) || include(string(@__DIR__, "/discrete_factor.jl"))

"""
	buckets(f::DiscreteFactor)::Dict

Build buckets over all arguments of the factor `f`.
"""
function buckets(f::DiscreteFactor)::Dict
	return buckets(f, rvs(f))
end

"""
	buckets(f::DiscreteFactor, args::Vector{DiscreteRV})::Dict

Build buckets for the factor `f` while considering only a subset `args`
of the arguments of `f`.
"""
function buckets(f::DiscreteFactor, args::Vector{DiscreteRV})::Dict
	# Note: Currently only for Boolean RVs
	@assert all(x -> range(x) == [true, false], args)
	buckets = Dict()
	for c in sort([collect((Base.Iterators.product(map(x -> range(x), rvs(f))...)))...], rev=true)
		c = collect(c)
		p = potential(f, c)
		counts = [0, 0]
		for pos in eachindex(c)
			# Note: Only for Boolean RVs
			if c[pos] == true
				counts[1] += 1
			else
				counts[2] += 1
			end
		end
		if !haskey(buckets, counts)
			buckets[counts] = Multiset()
		end
		push!(buckets[counts], p)
	end

	return buckets
end

"""
	buckets_ordered(f::DiscreteFactor, dosort::Bool)::Tuple{OrderedDict, Dict}

Return a tuple containing the buckets (in order of ascending degree of
freedom if `dosort` is `true`) and a dictionary mapping each bucket to the
corresponding configurations (assignments of values to the arguments of `f`).
"""
function buckets_ordered(f::DiscreteFactor, dosort::Bool)::Tuple{OrderedDict, Dict}
	return buckets_ordered(f, rvs(f), dosort)
end

"""
	buckets_ordered(f::DiscreteFactor, args::Vector{DiscreteRV}, dosort::Bool)::Tuple{OrderedDict, Dict}

Build buckets for the factor `f` while considering only a subset `args`
of the arguments of `f`.
Return a tuple containing the buckets (in order of ascending degree of
freedom if `dosort` is `true`) and a dictionary mapping each bucket to the
corresponding configurations (assignments of values to the arguments of `f`).
"""
function buckets_ordered(
	f::DiscreteFactor,
	args::Vector{DiscreteRV},
	dosort::Bool
)::Tuple{OrderedDict, Dict}
	# Note: Currently only for Boolean RVs
	@assert all(x -> range(x) == [true, false], args)
	buckets = Dict()
	bucket_assignments = Dict()
	for c in sort([collect((Base.Iterators.product(map(x -> range(x), rvs(f))...)))...], rev=true)
		c_as_bool = c
		c = collect(c)
		p = potential(f, c)
		counts = [0, 0]
		for pos in eachindex(c)
			# Note: Only for Boolean RVs
			if c[pos] == true
				counts[1] += 1
			else
				counts[2] += 1
			end
		end
		!haskey(buckets, counts) && (buckets[counts] = [])
		!haskey(bucket_assignments, counts) && (bucket_assignments[counts] = [])
		push!(buckets[counts], p)
		push!(bucket_assignments[counts], c_as_bool)
	end

	if dosort
		degs_of_freedom = Dict()
		for (c, p) in pairs(buckets)
			degs_of_freedom[c] = degree_of_freedom(p)
		end
		sorted_pairs = sort(collect(pairs(buckets)), by=x-> degs_of_freedom[x[1]], rev = false)
		return OrderedDict(sorted_pairs), bucket_assignments
	else
		return OrderedDict(buckets), bucket_assignments
	end
end

"""
	degree_of_freedom(values::Vector)::Int

Compute the degree of freedom of a list of values.
"""
function degree_of_freedom(values::Vector)::Int
	prod = 1
	for val in unique(values)
		prod *= count(x -> x == val, values)
	end
	return prod
end

"""
	permute_args!(f1::DiscreteFactor, f2::DiscreteFactor)::Bool

Permute the arguments of `f1` such that its potentials are identical to
those of `f2`. Return `true` if a permutation was found and performed,
otherwise `false` (in this case, no changes are made).
"""
function permute_args!(f1::DiscreteFactor, f2::DiscreteFactor)::Bool
	@assert length(rvs(f1)) == length(rvs(f2))

	# Note: Currently only for Boolean RVs
	@assert all(x -> range(x) == [true, false], rvs(f1))
	@assert all(x -> range(x) == [true, false], rvs(f2))

	for perm in permutations(1:length(rvs(f1)))
		found_mismatch = false
		for c in Base.Iterators.product(map(x -> range(x), rvs(f1))...)
			conf = collect(c)
			conf_permutated = [conf[perm[i]] for i in eachindex(conf)]
			if potential(f2, conf) != potential(f1, conf_permutated)
				found_mismatch = true
				break
			end
		end
		if !found_mismatch
			rvs_new_order = Vector{DiscreteRV}(undef, length(rvs(f1)))
			for i in eachindex(perm)
				rvs_new_order[perm[i]] = f1.rvs[i]
			end
			f1.rvs = rvs_new_order
			f1.potentials = f2.potentials
			return true
		end
	end

	return false
end

"""
	valuepositions(row::Tuple)::Dict

Return a dictionary that maps each value in `row` to the positions where it
occurs in `row`.
"""
function valuepositions(row::Tuple)::Dict
	dict = Dict()
	for val in unique(row)
		dict[val] = findall(x -> x == val, row)
	end
	return dict
end

"""
	print_buckets(buckets::Dict, io::IO = stdout)

Print the buckets of a factor `f` on the given output stream `io`.
"""
function print_buckets(buckets::OrderedDict, io::IO = stdout)
	for b in sort(collect(keys(buckets)), rev=true)
		print(io, string(b, " => ", join(buckets[b], ", "), "\n"))
	end
	print(io, "\n")
end