using Statistics

"""
	prepare_times_main(file::String)

Build averages over multiple runs and write the results into a new `.csv` file
that is used for plotting in the main paper.
"""
function prepare_times_main(file::String)
	if !isfile(file)
		@warn "File '$file' does not exist and is ignored."
		return
	end

	new_file = replace(file, ".csv" => "-prepared-main.csv")
	if isfile(new_file)
		@warn "File '$new_file' already exists and is ignored."
		return
	end

	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			algo = cols[5]
			n = cols[2]
			time = cols[6]
			time != "timeout" || (time = "NaN")
			haskey(averages, algo) || (averages[algo] = Dict())
			haskey(averages[algo], n) || (averages[algo][n] = [])
			push!(averages[algo][n], parse(Float64, time))
		end
	end

	open(new_file, "a") do io
		write(io, "n,algo,min_t,max_t,mean_t,median_t,std\n")
		for (algo, ns) in averages
			for (n, times) in ns
				# Average with timeouts does not work
				any(t -> isnan(t), times) && continue
				write(io, string(
					parse(Int, n), ",",
					algo, ",",
					minimum(times), ",",
					maximum(times), ",",
					mean(times), ",",
					median(times), ",",
					std(times), "\n"
				))
			end
		end
	end
end

"""
	prepare_times_appendix(file::String)

Build averages over multiple runs and write the results into a new `.csv` file
that is used for plotting in the appendix.
"""
function prepare_times_appendix(file::String)
	if !isfile(file)
		@warn "File '$file' does not exist and is ignored."
		return
	end

	new_file = replace(file, ".csv" => "-prepared-appendix.csv")
	if isfile(new_file)
		@warn "File '$new_file' already exists and is ignored."
		return
	end

	averages = Dict()
	open(file, "r") do io
		readline(io) # Remove header
		for line in readlines(io)
			cols = split(line, ",")
			_, n, eq, t, algo, time = cols
			time != "timeout" || (time = "NaN")
			haskey(averages, algo) || (averages[algo] = Dict())
			haskey(averages[algo], n) || (averages[algo][n] = Dict())
			haskey(averages[algo][n], eq) || (averages[algo][n][eq] = Dict())
			haskey(averages[algo][n][eq], t) || (averages[algo][n][eq][t] = [])
			push!(averages[algo][n][eq][t], parse(Float64, time))
		end
	end

	open(new_file, "a") do io
		write(io, "n,iseq,type,algo,min_t,max_t,mean_t,median_t,std\n")
		for (algo, ns) in averages
			for (n, eqs) in ns
				for (eq, ts) in eqs
					for (t, times) in ts
						# Average with timeouts does not work
						any(t -> isnan(t), times) && continue
						write(io, string(
							parse(Int, n), ",",
							eq, ",",
							t, ",",
							algo, ",",
							minimum(times), ",",
							maximum(times), ",",
							mean(times), ",",
							median(times), ",",
							std(times), "\n"
						))
					end
				end
			end
		end
	end
end


### Entry point ###
if abspath(PROGRAM_FILE) == @__FILE__
	prepare_times_main(string(@__DIR__, "/results.csv"))
	prepare_times_appendix(string(@__DIR__, "/results.csv"))
end