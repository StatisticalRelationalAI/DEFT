using BenchmarkTools

@isdefined(DiscreteFactor)        || include(string(@__DIR__, "/discrete_factor.jl"))
@isdefined(load_from_file)        || include(string(@__DIR__, "/helper.jl"))
@isdefined(is_exchangeable_naive) || include(string(@__DIR__, "/is_exchangeable.jl"))

"""
	run_benchmark(f::String, algo::String)

Run the benchmark for a given file and algorithm.
"""
function run_benchmark(f::String, algo::String)
	f1, f2 = load_from_file(f)
	try
		if algo == "naive"
			fn = is_exchangeable_naive
		elseif algo == "filter"
			fn = is_exchangeable_filter
		elseif algo == "deft"
			fn = is_exchangeable_deft
		else
			println("Error: Unknown algorithm '$algo'.")
		end
		result = @benchmark (global iseq = $fn($f1, $f2))
		print(string(mean(result.times), ",", iseq))
	catch e
		print(string(typeof(e), ": ", e))
	end
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	if length(ARGS) != 2 || !isfile(ARGS[1]) || !(ARGS[2] in ["naive", "filter", "deft"])
		@error string(
			"Run this file via 'julia $PROGRAM_FILE <path> <algo>' ",
			"with <path> being the path to a data file on which to run the ",
			"algorithm <algo> (one of 'naive', 'filter', 'deft')."
		)
		exit()
	end
	run_benchmark(ARGS[1], ARGS[2])
end