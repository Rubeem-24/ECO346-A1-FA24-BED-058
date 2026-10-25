library(ggplot2)
library(svglite)
library(dplyr)

person_path <- "data/pslm_person_subset.csv"
household_path <- "data/pslm_hh_subset.csv"

if (!file.exists(person_path)) {
  stop("Run this script from the repository root.")
}

dir.create("figures", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

people <- read.csv(person_path)
households <- read.csv(household_path)

households <- households[
  , c("hhid", "hhweight", "prov_code", "urban_rural")
]

survey <- merge(people, households, by = "hhid", all.x = TRUE)

literacy_data <- subset(
  survey,
  prov_code == 3 &
    urban_rural == 1 &
    age >= 10 &
    age <= 64 &
    !is.na(literate)
)

literacy_data <- literacy_data |>
  mutate(
    band_start = floor(age / 5) * 5,
    midpoint = band_start + 2,
    gender = ifelse(sex == 1, "Men", "Women")
  )

age_summary <- literacy_data |>
  group_by(band_start, midpoint, gender) |>
  summarise(
    observations = n(),
    literacy_rate = 100 * sum(hhweight * literate) / sum(hhweight),
    .groups = "drop"
  ) |>
  mutate(small_group = observations < 30)

female_data <- subset(
  age_summary,
  gender == "Women",
  select = c(band_start, midpoint, observations, literacy_rate)
)

male_data <- subset(
  age_summary,
  gender == "Men",
  select = c(band_start, midpoint, observations, literacy_rate)
)

age_table <- merge(
  female_data,
  male_data,
  by = c("band_start", "midpoint"),
  suffixes = c("_women", "_men")
)

age_table$age_band <- paste0(
  age_table$band_start, "-", age_table$band_start + 4
)

age_table$literacy_gap <-
  age_table$literacy_rate_men - age_table$literacy_rate_women

age_table <- age_table[
  order(age_table$band_start),
  c(
    "age_band", "midpoint",
    "observations_women", "literacy_rate_women",
    "observations_men", "literacy_rate_men",
    "literacy_gap"
  )
]

names(age_table) <- c(
  "band", "mid", "n_women", "rate_women",
  "n_men", "rate_men", "gap"
)

export_table <- age_table
export_table[, c("rate_women", "rate_men", "gap")] <-
  round(export_table[, c("rate_women", "rate_men", "gap")], 1)

write.csv(
  export_table,
  "tables/band_table_R.csv",
  row.names = FALSE
)

print(export_table)

get_rate <- function(age_group, column_name) {
  sprintf(
    "%.1f",
    age_table[[column_name]][age_table$band == age_group]
  )
}

cat(
  "Women 15-19:", get_rate("15-19", "rate_women"),
  " Men 15-19:", get_rate("15-19", "rate_men"), "\n"
)

cat(
  "Women 55-59:", get_rate("55-59", "rate_women"),
  " Men 55-59:", get_rate("55-59", "rate_men"), "\n"
)

largest_gap <- age_table[which.max(age_table$gap), ]

cat(
  "Largest gap:", largest_gap$band, "=",
  sprintf("%.1f", largest_gap$gap), "points\n"
)

cat(
  "Literacy sample size:", nrow(literacy_data),
  " Smallest cell:", min(age_summary$observations), "\n"
)

age_labels <- paste0(
  seq(10, 60, by = 5), "-",
  seq(14, 64, by = 5)
)

gender_colours <- c(
  Women = "#b5532a",
  Men = "#1f4e79"
)

last_points <- subset(age_summary, midpoint == 62)

gap_label_y <- (
  largest_gap$rate_women + largest_gap$rate_men
) / 2

plot_caption <- paste0(
  "Source: PSLM 2019-20, person file merged with household file. ",
  "Sample: persons aged 10-64 in rural Sindh with non-missing literacy (n = ",
  format(nrow(literacy_data), big.mark = ","), ").\n",
  "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n",
  "Hollow markers: cells with fewer than 30 observations",
  if (any(age_summary$small_group)) "." else " (none in this sample)."
)

literacy_plot <- ggplot(
  age_summary,
  aes(
    x = midpoint,
    y = literacy_rate,
    colour = gender,
    group = gender
  )
) +
  geom_line(linewidth = 0.9) +
  geom_point(
    aes(shape = small_group),
    size = 3.2,
    stroke = 1.1,
    fill = "white"
  ) +
  scale_shape_manual(
    values = c("FALSE" = 16, "TRUE" = 21),
    guide = "none"
  ) +
  scale_colour_manual(
    values = gender_colours,
    guide = "none"
  ) +
  geom_text(
    data = last_points,
    aes(label = gender),
    hjust = 0,
    nudge_x = 1,
    fontface = "bold",
    size = 4.2
  ) +
  geom_segment(
    data = largest_gap,
    aes(
      x = mid,
      xend = mid,
      y = rate_women,
      yend = rate_men
    ),
    inherit.aes = FALSE,
    colour = "grey30",
    arrow = arrow(
      ends = "both",
      length = grid::unit(0.08, "inches")
    )
  ) +
  annotate(
    "text",
    x = largest_gap$mid + 1,
    y = gap_label_y,
    hjust = 0,
    size = 3.8,
    colour = "grey20",
    label = paste0(
      "Largest gap, ages ", largest_gap$band, ":\n",
      sprintf("%.1f", largest_gap$gap), " points"
    )
  ) +
  scale_x_continuous(
    breaks = seq(12, 62, by = 5),
    labels = age_labels,
    limits = c(10, 70),
    expand = expansion(0)
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, by = 20),
    labels = function(values) paste0(values, "%")
  ) +
  labs(
    title = paste0(
      "In rural Sindh, men are at least 22 percentage points more literate\n",
      "than women in every age band"
    ),
    x = "Age band (years)",
    y = "Literate (weighted %)",
    caption = plot_caption
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
  "figures/literacy_by_age.svg",
  literacy_plot,
  width = 9,
  height = 5.8
)