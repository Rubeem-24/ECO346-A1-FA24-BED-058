# 03_literacy.R  --  Question 3 (and the redesign of Question 4):
# weighted literacy rate by five-year age band, women and men.
# Variant 2 = Sindh rural.   Run from the repository root:  Rscript scripts/03_literacy.R

library(ggplot2)
library(svglite)
library(dplyr)

if (!file.exists("data/pslm_person_subset.csv")) stop("Run this script from the repository root.")
dir.create("figures", showWarnings = FALSE)
dir.create("tables",  showWarnings = FALSE)

# --- data: same merge as in the other scripts ---
pp <- read.csv("data/pslm_person_subset.csv")
hh <- read.csv("data/pslm_hh_subset.csv")
hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
d  <- merge(pp, hh, by = "hhid", all.x = TRUE)

lit <- d[d$prov_code == 3 & d$urban_rural == 1 &
         d$age >= 10 & d$age <= 64 & !is.na(d$literate), ]

# --- five-year bands 10-14, ..., 60-64, plotted at the midpoint (12, 17, ..., 62) ---
lit$band_start <- floor(lit$age / 5) * 5      # 10, 15, ..., 60
lit$mid        <- lit$band_start + 2
lit$sex_lab    <- ifelse(lit$sex == 1, "Men", "Women")

# --- one row per band and sex: unweighted n and weighted literacy rate (percent) ---
cells <- lit |>
  group_by(band_start, mid, sex_lab) |>
  summarise(n        = n(),
            lit_rate = 100 * sum(hhweight * literate) / sum(hhweight),
            .groups  = "drop") |>
  mutate(thin = n < 30)                        # thin cell: fewer than 30 observations

# --- wide band table for the README ---
women <- cells[cells$sex_lab == "Women", c("band_start", "mid", "n", "lit_rate")]
men   <- cells[cells$sex_lab == "Men",   c("band_start", "mid", "n", "lit_rate")]
band_table <- merge(women, men, by = c("band_start", "mid"), suffixes = c("_women", "_men"))
band_table$band <- paste0(band_table$band_start, "-", band_table$band_start + 4)
band_table$gap  <- band_table$lit_rate_men - band_table$lit_rate_women
band_table <- band_table[order(band_table$band_start),
                         c("band", "mid", "n_women", "lit_rate_women", "n_men", "lit_rate_men", "gap")]
names(band_table) <- c("band", "mid", "n_women", "rate_women", "n_men", "rate_men", "gap")
out <- band_table
out[, c("rate_women", "rate_men", "gap")] <- round(out[, c("rate_women", "rate_men", "gap")], 1)
write.csv(out, "tables/band_table_R.csv", row.names = FALSE)
print(out)

# --- numbers for the Google Form ---
g <- function(b, col) sprintf("%.1f", band_table[[col]][band_table$band == b])
cat("Women 15-19:", g("15-19", "rate_women"), " Men 15-19:", g("15-19", "rate_men"), "\n")
cat("Women 55-59:", g("55-59", "rate_women"), " Men 55-59:", g("55-59", "rate_men"), "\n")
gap_row <- band_table[which.max(band_table$gap), ]
cat("Largest gap:", gap_row$band, "=", sprintf("%.1f", gap_row$gap), "points\n")
cat("Literacy sample size:", nrow(lit), " Smallest cell:", min(cells$n), "\n")

# --- the figure ---
band_labels <- paste0(seq(10, 60, 5), "-", seq(14, 64, 5))
colours     <- c(Women = "#b5532a", Men = "#1f4e79")
ends        <- cells[cells$mid == 62, ]                       # last point of each series
gap_mid_y   <- (gap_row$rate_women + gap_row$rate_men) / 2

caption <- paste0("Source: PSLM 2019-20, person file merged with household file. ",
                  "Sample: persons aged 10-64 in rural Sindh with non-missing literacy (n = ",
                  format(nrow(lit), big.mark = ","), ").\n",
                  "Weighted by hhweight; each marker is a five-year band plotted at its midpoint.\n",
                  "Hollow markers: cells with fewer than 30 observations",
                  if (any(cells$thin)) "." else " (none in this sample).")

p <- ggplot(cells, aes(x = mid, y = lit_rate, colour = sex_lab, group = sex_lab)) +
  geom_line(linewidth = 0.9) +
  geom_point(aes(shape = thin), size = 3.2, stroke = 1.1, fill = "white") +
  scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 21), guide = "none") +
  scale_colour_manual(values = colours, guide = "none") +
  # direct labels at the end of each series
  geom_text(data = ends, aes(label = sex_lab), hjust = 0, nudge_x = 1,
            fontface = "bold", size = 4.2) +
  # annotation of the band with the largest gap
  geom_segment(data = gap_row,
               aes(x = mid, xend = mid, y = rate_women, yend = rate_men),
               inherit.aes = FALSE, colour = "grey30",
               arrow = arrow(ends = "both", length = unit(0.08, "inches"))) +
  annotate("text", x = gap_row$mid + 1, y = gap_mid_y, hjust = 0, size = 3.8, colour = "grey20",
           label = paste0("Largest gap, ages ", sub("-", "-", gap_row$band), ":\n",
                          sprintf("%.1f", gap_row$gap), " points")) +
  scale_x_continuous(breaks = seq(12, 62, 5), labels = band_labels,
                     limits = c(10, 70), expand = expansion(0)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  labs(title = "In rural Sindh, men are at least 22 percentage points more literate\nthan women in every age band",
       x = "Age band (years)", y = "Literate (weighted %)", caption = caption) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.caption = element_text(hjust = 0, size = 9, colour = "grey30"),
        plot.title = element_text(face = "bold"))

ggsave("figures/literacy_by_age.svg", p, width = 9, height = 5.8)