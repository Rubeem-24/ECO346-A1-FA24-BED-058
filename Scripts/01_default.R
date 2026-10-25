library(ggplot2)
library(svglite)

person_file <- "data/pslm_person_subset.csv"
household_file <- "data/pslm_hh_subset.csv"

if (!file.exists(person_file)) {
  stop("Run this script from the repository root.")
}

if (!dir.exists("figures")) {
  dir.create("figures")
}

persons <- read.csv(person_file)
households <- read.csv(household_file)

households <- households[
  , c("hhid", "hhweight", "prov_code", "urban_rural")
]

combined_data <- merge(
  persons,
  households,
  by = "hhid",
  all.x = TRUE
)

literacy_data <- subset(
  combined_data,
  prov_code == 3 &
    urban_rural == 1 &
    age >= 10 &
    age <= 64 &
    !is.na(literate)
)

message("Literacy sample size: ", nrow(literacy_data))

default_plot <- ggplot(
  literacy_data,
  aes(x = age, y = literate)
) +
  geom_point()

ggsave(
  filename = "figures/default.svg",
  plot = default_plot
)