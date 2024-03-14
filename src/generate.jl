using Random

@isdefined(DiscreteFactor) || include("discrete_factor.jl")
@isdefined(save_to_file)   || include("helper.jl")

"""
	generate(n::Int, iseq::Bool, gen::Function, p::Float64=1.0)::Tuple{DiscreteFactor, DiscreteFactor}

Generate two discrete factors with `n` random binary random variables each,
using the given generator function `gen` with parameters `params` to generate
potentials.
If `iseq` is `true`, both factors entail equivalent semantics.
"""
function generate(
	n::Int,
	iseq::Bool,
	gen::Function,
	p::Float64=2.0
)::Tuple{DiscreteFactor, DiscreteFactor}
	p1 = gen([[true, false] for _ in 1:n], p > 1.0 ? 1 : p, (p > 1.0 ? [] : [1])...)
	if iseq
		p2 = p1
	else
		p2 = gen([[true, false] for _ in 1:n], p > 1.0 ? 2 : p, (p > 1.0 ? [] : [2])...)
		idx = rand(1:length(p2))
		p2[idx] = (p2[idx][1], p2[idx][2] + 2^n)
	end

	f1 = DiscreteFactor("f1", [DiscreteRV("R$i") for i in 1:n], p1)
	f2 = DiscreteFactor("f2", [DiscreteRV("R'$i") for i in 1:n], p2)

	permute_factor!(f2)

	return f1, f2
end

"""
	gen_asc_pots(rs::Array, start::Int=1)::Vector{Tuple{Vector, Float64}}

Generate ascending potentials for a given array of ranges, starting at `start`.
"""
function gen_asc_pots(rs::Array, start::Int=1)::Vector{Tuple{Vector, Float64}}
	length(rs) > 5 && @warn("Generating at least $(2^length(rs)) potentials!")

	potentials = []
	i = start
	for conf in Iterators.product(rs...)
		push!(potentials, ([conf...], i))
		i += 1
	end

	return potentials
end

"""
	gen_same_pots(rs::Array, val::Int=1)::Vector{Tuple{Vector, Float64}}

Generate identical potentials for all assignments for a given array of ranges.
"""
function gen_same_pots(rs::Array, val::Int=1)::Vector{Tuple{Vector, Float64}}
	length(rs) > 5 && @warn("Generating at least $(2^length(rs)) potentials!")

	potentials = []
	for conf in Iterators.product(rs...)
		push!(potentials, ([conf...], val))
	end

	return potentials
end

"""
	gen_mixed_pots(rs::Array, p::Float64=0.1, seed::Int=123)::Vector{Tuple{Vector, Float64}}

Generate mixed potentials for a given array of ranges, with a proportion of
about `p` of the potentials being identical.
"""
function gen_mixed_pots(rs::Array, p::Float64=0.1, seed::Int=123)::Vector{Tuple{Vector, Float64}}
	Random.seed!(seed)

	length(rs) > 5 && @warn("Generating at least $(2^length(rs)) potentials!")

	potentials = []
	i = 1
	for conf in Iterators.product(rs...)
		if rand() < p
			push!(potentials, ([conf...], 1))
		else
			push!(potentials, ([conf...], i))
		end
		i += 1
	end

	return potentials
end

"""
	permute_factor!(f::DiscreteFactor, seed::Int=123)

Permute the arguments of the given factor `f` (without changing its semantics).
"""
function permute_factor!(f::DiscreteFactor, seed::Int=123)
	Random.seed!(seed)

	permutation = shuffle(1:length(rvs(f)))
	new_potentials = Dict()
	for c in collect(Base.Iterators.product(map(x -> range(x), f.rvs)...))
		new_c = collect(c)
		new_c = [new_c[i] for i in permutation]
		new_potentials[join(new_c, ",")] = potential(f, collect(c))
	end
	f.potentials = new_potentials
	f.rvs = [f.rvs[i] for i in permutation]
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	dir = string(@__DIR__, "/../data/")
	!isdir(dir) && mkdir(dir)
	for n in [2,4,6,8,10,12,14,16]
		nstr = lpad(n, 2, "0")
		for iseq in [true, false]
			save_to_file(
				generate(n, iseq, gen_asc_pots),
				string(dir, "asc-n=$nstr-$iseq.ser")
			)
			save_to_file(
				generate(n, iseq, gen_same_pots),
				string(dir, "same-n=$nstr-$iseq.ser")
			)
			for p in [0.1, 0.2, 0.5, 0.8, 0.9]
				pstr = lpad(floor(Int, p * 100), 3, "0")
				save_to_file(
					generate(n, iseq, gen_mixed_pots, p),
					string(dir, "mixed-n=$nstr-p=$pstr-$iseq.ser")
				)
			end
		end
	end
end