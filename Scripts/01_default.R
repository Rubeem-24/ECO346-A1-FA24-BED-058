# 01_default.R  --  Question 4: R's default scatterplot, nothing added.
# Variant 2 = Sindh rural (prov_code 3, urban_rural 1).
# Run from the repository root:  Rscript scripts/01_default.R

library(ggplot2)
library(svglite)   # lets ggsave() write SVG

if (!file.exists("data/pslm_person_subset.csv")) stop("Run this script from the repository root.")
dir.create("figures", showWarnings = FALSE)

# --- read the local copies and attach hhweight, prov_code, urban_rural by hhid ---
pp <- read.csv("data/pslm_person_subset.csv")
hh <- read.csv("data/pslm_hh_subset.csv")
hh <- hh[, c("hhid", "hhweight", "prov_code", "urban_rural")]
d  <- merge(pp, hh, by = "hhid", all.x = TRUE)

# --- literacy sample: variant 2, aged 10-64, literate not missing ---
lit <- d[d$prov_code == 3 & d$urban_rural == 1 &
         d$age >= 10 & d$age <= 64 & !is.na(d$literate), ]
cat("Literacy sample size:", nrow(lit), "\n")

# --- the default figure: literate against age, nothing else ---
p <- ggplot(lit, aes(age, literate)) + geom_point()
ggsave("figures/default.svg", p)