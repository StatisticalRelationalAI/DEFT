library(ggplot2)
library(dplyr)
library(patchwork)
library(stringr)
library(tikzDevice)

use_tikz = TRUE

file_main = "results-prepared-main.csv"
file_app = "results-prepared-appendix.csv"

if (use_tikz) {
  lpos = c(0.13, 0.75)
} else {
  lpos = c(0.075, 0.85)
}

if (file.exists(file_main)) {
  data_main = read.csv(file = file_main, sep=",", dec=".")

  data_main["algo"][data_main["algo"] == "naive"]  = "Naive"
  data_main["algo"][data_main["algo"] == "filter"] = "ACP"
  data_main["algo"][data_main["algo"] == "deft"]   = "DEFT"
  data_main = rename(data_main, "Algorithm" = "algo")

  if (use_tikz) {
    tikz("plot-avg.tex", standAlone = FALSE, width = 3.3, height = 1.6)
  } else {
    pdf(file = "plot-avg.pdf", height = 2.4)
  }

  p <- ggplot(data_main, aes(x=n, y=mean_t, group=Algorithm, color=Algorithm)) +
    geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
    geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
    xlab("$n$") +
    ylab("time (ms)") +
    scale_y_log10(breaks = c(1, 100, 10000)) +
    theme_classic() +
    theme(
      axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
      axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
      legend.position = lpos,
      legend.title = element_blank(),
      legend.text = element_text(size=8),
      legend.background = element_rect(fill = NA),
      legend.spacing.y = unit(0, 'mm')
    ) +
    guides(fill = "none") +
    scale_color_manual(values=c(
      rgb(247,192,26, maxColorValue=255),
      rgb(78,155,133, maxColorValue=255),
      rgb(37,122,164, maxColorValue=255)
    )) +
    scale_fill_manual(values=c(
      rgb(247,192,26, maxColorValue=255),
      rgb(78,155,133, maxColorValue=255),
      rgb(37,122,164, maxColorValue=255)
    ))

  print(p)
  dev.off()
}

if (file.exists(file_app)) {
  data_app = read.csv(file = file_app, sep=",", dec=".")

  data_app["algo"][data_app["algo"] == "naive"]  = "Naive"
  data_app["algo"][data_app["algo"] == "filter"] = "ACP"
  data_app["algo"][data_app["algo"] == "deft"]   = "DEFT"
  data_app = rename(data_app, "Algorithm" = "algo")

  for (t in c("asc", "same", "mixed")) {
    for (eq in c("true", "false")) {
      data_filtered = filter(data_app, type == t)
      data_filtered = filter(data_filtered, iseq == eq)
      if (nrow(data_filtered) == 0) next

      if (use_tikz) {
        tikz(paste("plot-", t, "-", eq, ".tex", sep=""), standAlone = FALSE, width = 3.3, height = 1.6)
      } else {
        pdf(file = paste("plot-", t, "-", eq, ".pdf", sep=""), height = 2.4)
      }

      p <- ggplot(data_filtered, aes(x=n, y=mean_t, group=Algorithm, color=Algorithm)) +
        geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
        geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
        xlab("$n$") +
        ylab("time (ms)") +
        scale_y_log10(breaks = c(1, 100, 10000)) +
        theme_classic() +
        theme(
          axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
          axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
          legend.position = lpos,
          legend.title = element_blank(),
          legend.text = element_text(size=8),
          legend.background = element_rect(fill = NA),
          legend.spacing.y = unit(0, 'mm')
        ) +
        guides(fill = "none") +
        scale_color_manual(values=c(
          rgb(247,192,26, maxColorValue=255),
          rgb(78,155,133, maxColorValue=255),
          rgb(37,122,164, maxColorValue=255)
        )) +
        scale_fill_manual(values=c(
          rgb(247,192,26, maxColorValue=255),
          rgb(78,155,133, maxColorValue=255),
          rgb(37,122,164, maxColorValue=255)
        ))

      print(p)
      dev.off()
    } 
  }
}