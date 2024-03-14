@isdefined(DiscreteFactor)        || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(buckets)               || include(string(@__DIR__, "/buckets.jl"))
@isdefined(is_exchangeable_naive) || include(string(@__DIR__, "/is_exchangeable.jl"))
@isdefined(load_from_file)        || include(string(@__DIR__, "/helper.jl"))

f1 = DiscreteFactor(
	"f1",
	[DiscreteRV("R1"), DiscreteRV("R2"), DiscreteRV("R3")],
	[
		([true,  true,  true],  1.0),
		([true,  true,  false], 2.0),
		([true,  false, true],  3.0),
		([true,  false, false], 4.0),
		([false, true,  true],  5.0),
		([false, true,  false], 6.0),
		([false, false, true],  6.0),
		([false, false, false], 7.0),
	]
)

f2 = DiscreteFactor(
	"f2",
	[DiscreteRV("R4"), DiscreteRV("R5"), DiscreteRV("R6")],
	[
		([true,  true,  true],  1.0),
		([true,  true,  false], 3.0),
		([true,  false, true],  5.0),
		([true,  false, false], 6.0),
		([false, true,  true],  2.0),
		([false, true,  false], 4.0),
		([false, false, true],  6.0),
		([false, false, false], 7.0),
	]
)

# f1, f2 = load_from_file(string(@__DIR__, "/../data/asc-n=07-true.ser"))

### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	"debug" in ARGS && (ENV["JULIA_DEBUG"] = "all")
	println("=> Naive:")
	iseq_naive = is_exchangeable_naive(f1,f2)
	println(string("Exchangeable: ", iseq_naive))

	println("=> DEFT:")
	iseq_deft = is_exchangeable_deft(f1, f2)
	println(string("Exchangeable: ", iseq_deft))
end