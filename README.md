# Detection of Exchangeable Factors (DEFT)

This repository contains the source code of the detection of exchangeable
factors (DEFT) algorithm that has been presented in the paper
"Efficient Detection of Exchangeable Factors in Factor Graphs"
by Malte Luttermann, Johann Machemer, and Marcel Gehrke (FLAIRS 2024).

Our implementation uses the [Julia programming language](https://julialang.org).

## Computing Infrastructure and Required Software Packages

All experiments were conducted using Julia version 1.8.1 together with the
following packages:
- BenchmarkTools v1.3.1
- Combinatorics v1.0.2
- Multisets v0.4.4
- OrderedCollections v1.6.3

## Instance Generation

First, the input instances must be generated.
To do so, run `julia generate.jl` in the `src/` directory.
The input instances are then written into the `data/` directory.

## Running the Experiments

After the instances have been generated, the experiments can be started by
running `julia run_eval.jl` in the `src/` directory.
All results are written into the `results/` directory.

To create the plots, run `julia prepare_plot.jl` in the `results/` directory
and afterwards execute the R script `plot.r` (also in the `results/` directory).
The R script will then create a bunch of `.tex` files in the `results/` directory
containing the plots of the experiments.
To generate the plots as `.pdf` files instead, set `use_tikz = FALSE` in
line 7 of `plot.r` before executing the R script `plot.r`.