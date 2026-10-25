library(ggplot2)
library(svglite)

person_path <- "data/pslm_person_subset.csv"
household_path <- "data/pslm_hh_subset.csv"

if (!file.exists(person_path)) {
  stop("Run this script from the repository root.")
}

dir.create("figures", showWarnings = FALSE)

people <- read.csv(person_path)
households <- read.csv(household_path)

households <- households[
  , c("hhid", "hhweight", "prov_code", "urban_rural")
]

survey_data <- merge(people, households, by = "hhid", all.x = TRUE)

student_data <- subset(
  survey_data,
  prov_code == 3 &
    urban_rural == 1 &
    !is.na(ed_total) &
    ed_total > 0
)

weighted_quantile <- function(values, weights, probability) {
  sorted_indices <- order(values)
  sorted_values <- values[sorted_indices]
  sorted_weights <- weights[sorted_indices]

  cumulative_share <- cumsum(sorted_weights) / sum(sorted_weights)
  sorted_values[which(cumulative_share >= probability)[1]]
}

student_count <- nrow(student_data)

median_weighted <- weighted_quantile(
  student_data$ed_total, student_data$hhweight, 0.5
)
median_unweighted <- median(student_data$ed_total)

percentile_10 <- weighted_quantile(
  student_data$ed_total, student_data$hhweight, 0.1
)
percentile_90 <- weighted_quantile(
  student_data$ed_total, student_data$hhweight, 0.9
)

percentile_ratio <- percentile_90 / percentile_10

outside_range <- student_data$ed_total < 100 |
  student_data$ed_total > 1e6

excluded_count <- sum(outside_range)

plot_data <- subset(
  student_data,
  ed_total >= 100 & ed_total <= 1e6
)

cat("Number of students:        ", student_count, "\n")
cat("Weighted median (Rs):      ", median_weighted, "\n")
cat("Unweighted median (Rs):    ", median_unweighted, "\n")
cat("Weighted 10th pct (Rs):    ", percentile_10, "\n")
cat("Weighted 90th pct (Rs):    ", percentile_90, "\n")
cat("p90 / p10 ratio:           ", sprintf("%.2f", percentile_ratio), "\n")
cat("Excluded from histogram:   ", excluded_count, "\n")

format_rupees <- function(value) {
  format(
    round(value),
    big.mark = ",",
    scientific = FALSE,
    trim = TRUE
  )
}

histogram <- ggplot(
  plot_data,
  aes(x = ed_total, weight = hhweight)
) +
  geom_histogram(
    aes(y = after_stat(density)),
    binwidth = 0.1,
    boundary = 2,
    closed = "left",
    fill = "#1f4e79",
    colour = "white"
  ) +
  scale_x_log10(
    breaks = 10^(2:6),
    labels = c(
      "Rs 100", "Rs 1,000", "Rs 10,000",
      "Rs 100,000", "Rs 1,000,000"
    )
  )

histogram_bins <- ggplot_build(histogram)$data[[1]]

density_area <- sum(
  histogram_bins$density *
    (histogram_bins$xmax - histogram_bins$xmin)
)

cat(
  "Area under histogram (should be 1):",
  round(density_area, 4),
  "\n"
)

peak_density <- max(histogram_bins$density)

final_plot <- histogram +
  geom_vline(
    xintercept = c(median_weighted, percentile_90),
    linetype = "dashed",
    colour = "#b5532a",
    linewidth = 0.7
  ) +
  annotate(
    "text",
    x = median_weighted,
    y = peak_density * 1.12,
    hjust = 1.08,
    vjust = 0,
    colour = "#b5532a",
    fontface = "bold",
    size = 3.8,
    label = paste0(
      "Weighted median\nRs ",
      format_rupees(median_weighted)
    )
  ) +
  annotate(
    "text",
    x = percentile_90,
    y = peak_density * 1.12,
    hjust = -0.08,
    vjust = 0,
    colour = "#b5532a",
    fontface = "bold",
    size = 3.8,
    label = paste0(
      "90th percentile\nRs ",
      format_rupees(percentile_90)
    )
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
  labs(
    title = paste0(
      "The middle 80% of rural Sindh's students cost their families\n",
      "between Rs ", format_rupees(percentile_10),
      " and Rs ", format_rupees(percentile_90), " a year"
    ),
    x = "Annual spending on the student's education (rupees, log scale)",
    y = "Density per log10 unit",
    caption = paste0(
      "Source: PSLM 2019-20, person file merged with household file. ",
      "Sample: ", format_rupees(student_count),
      " students (ed_total > 0), rural Sindh.\n",
      excluded_count,
      " student(s) outside Rs 100 - Rs 1,000,000 excluded from the histogram.\n",
      "Weighted by hhweight; bins 0.1 wide in log10 units."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(
      hjust = 0,
      size = 9,
      colour = "grey30"
    ),
    plot.title = element_text(face = "bold")
  )

ggsave(
  "figures/distribution.svg",
  final_plot,
  width = 9,
  height = 5.8
)