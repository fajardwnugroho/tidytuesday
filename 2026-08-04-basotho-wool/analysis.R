# ============================================================
# TidyTuesday | 2026-08-04 | Basotho Wool
#
# Three business questions:
#   1. Seasonality   - When does Lesotho's wool export revenue
#                      trough and peak? Is "winter" the right framing?
#   2. Top importer  - Is South Africa the real buyer, or a gateway
#                      for higher-value Chinese demand?
#   3. Trend         - How has the price per kg moved 2010-2024?
#
# Data: UN Comtrade (mirror trade, imports reported by partner).
# Value backbone: primary_value; falls back to fobvalue where the
# primary value is missing (China reports primary_value on only 40
# of 91 rows, but fobvalue on all 91).
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(tidyplots)
library(ggplot2)
library(scales)

data_file <- "data/basotho_wool.csv"
out_dir   <- "outputs"
fig_dir   <- "figures"
dir.create(out_dir, showWarnings = FALSE)
dir.create(fig_dir, showWarnings = FALSE)

# ---- 1. Load -------------------------------------------------

basotho_wool <- read_csv(data_file, show_col_types = FALSE)

# ---- 2. Prepare ----------------------------------------------

# HS 5103 "waste of wool" accounts for only 2 of 293 rows -> drop.
# All remaining rows are HS 5101 "wool, not carded or combed".
wool <- basotho_wool |>
  filter(cmd_code == "5101") |>
  mutate(
    value = if_else(is.na(primary_value), fobvalue, primary_value),
    month = as.integer(ref_month),
    year  = ref_year,
    season = case_when(
      month %in% c(12, 1, 2)  ~ "Summer",
      month %in% c(3, 4, 5)   ~ "Autumn",
      month %in% c(6, 7, 8)   ~ "Winter",
      month %in% c(9, 10, 11) ~ "Spring"
    ),
    season = factor(season, levels = c("Summer", "Autumn", "Winter", "Spring"))
  )

# ---- 3. Data quality ------------------------------------------
# Only South Africa reports all 12 months in most years. China and
# India have patchy coverage, so seasonality is restricted to South
# Africa on complete years.

monthly_coverage <- wool |>
  count(reporter_desc, year, name = "months_reported")

write_csv(monthly_coverage, file.path(out_dir, "monthly_coverage.csv"))

# ---- 4. Reporter totals (question 2) --------------------------

reporter_totals <- wool |>
  group_by(reporter_desc) |>
  summarise(
    value_usd = sum(value, na.rm = TRUE),
    qty_kg    = sum(qty, na.rm = TRUE),
    .groups   = "drop"
  ) |>
  mutate(
    value_M    = value_usd / 1e6,
    qty_Mkg    = qty_kg / 1e6,
    price_per_kg = value_usd / qty_kg,
    value_share = value_usd / sum(value_usd) * 100,
    qty_share   = qty_kg / sum(qty_kg) * 100
  ) |>
  arrange(desc(value_M))

write_csv(reporter_totals, file.path(out_dir, "reporter_totals.csv"))

# ---- 5. Seasonal profile (question 1, South Africa only) ------

sa_full_years <- wool |>
  filter(reporter_desc == "South Africa") |>
  count(year) |>
  filter(n == 12) |>
  pull(year)

seasonal_profile <- wool |>
  filter(reporter_desc == "South Africa", year %in% sa_full_years) |>
  group_by(month) |>
  summarise(
    mean_value_M = mean(value, na.rm = TRUE) / 1e6,
    min_value_M  = min(value, na.rm = TRUE) / 1e6,
    max_value_M  = max(value, na.rm = TRUE) / 1e6,
    n_years      = n_distinct(year),
    .groups      = "drop"
  )

write_csv(seasonal_profile, file.path(out_dir, "seasonal_profile.csv"))

# ---- 6. Price trend (question 3, South Africa annual) ---------

sa_price_trend <- wool |>
  filter(reporter_desc == "South Africa") |>
  group_by(year) |>
  summarise(
    price_per_kg    = sum(value, na.rm = TRUE) / sum(qty, na.rm = TRUE),
    value_M         = sum(value, na.rm = TRUE) / 1e6,
    qty_Mkg         = sum(qty, na.rm = TRUE) / 1e6,
    months_reported = n_distinct(month),
    .groups         = "drop"
  )

write_csv(sa_price_trend, file.path(out_dir, "sa_price_trend.csv"))

# ---- 7. Figures -------------------------------------------------

# Font used by the official sample chart; falls back to the system
# sans font if "Plus Jakarta Sans" is not installed.
font_family <- "Plus Jakarta Sans"

m_label <- function(x) scales::dollar(x, scale = 1 / 1e6, suffix = "M")
# formats a value already expressed in millions of USD
m_label_millions <- function(x) scales::dollar(x, suffix = "M")

# --- Figure 1: seasonal profile ----------------------------------
sa_seasonal <- wool |>
  filter(reporter_desc == "South Africa", year %in% sa_full_years) |>
  select(year, month, value)

fig_01 <- tidyplot(sa_seasonal, x = month, y = value) |>
  add_range_ribbon(alpha = 0.25) |>
  add_mean_line(linewidth = 0.8) |>
  add_mean_dot(size = 2) |>
  add_title("Basotho wool exports to South Africa: the low season runs autumn to winter") |>
  add_caption("Mean monthly import value reported by South Africa (HS 5101, mirror trade). Ribbon shows the min-max across 11 complete years (2010-15, 2017, 2021-24). The winter window (Jun-Aug) is shaded; the recovery begins in spring (Sep-Oct).") |>
  adjust_x_axis(breaks = 1:12, labels = month.abb) |>
  adjust_y_axis(labels = m_label) |>
  adjust_y_axis_title("Mean monthly value (USD)") |>
  adjust_x_axis_title("Month") |>
  adjust_font(fontsize = 11, family = font_family) |>
  theme_tidyplot() +
  annotate("rect", xmin = 5.5, xmax = 8.5, ymin = -Inf, ymax = Inf,
           fill = "#4472C4", alpha = 0.12) +
  annotate("text", x = 7, y = 4.2,
           label = "Winter\n(Jun-Aug)", size = 3.5,
           color = "#4472C4", fontface = "bold") +
  annotate("text", x = 10.6, y = max(seasonal_profile$mean_value_M) + 0.25,
           label = paste0("Peak ", m_label_millions(max(seasonal_profile$mean_value_M))),
           size = 3.5, fontface = "bold", color = "#2E7D32") +
  annotate("text", x = 5.6, y = min(seasonal_profile$mean_value_M) + 0.1,
           label = paste0("Trough ", m_label_millions(min(seasonal_profile$mean_value_M))),
           size = 3.5, fontface = "bold", color = "#C62828")

ggsave(file.path(fig_dir, "fig_01_seasonal_profile.png"),
       plot = fig_01, width = 9.5, height = 4.5, dpi = 300)

# --- Figure 2: gateway vs destination ------------------------------
share_long <- reporter_totals |>
  select(reporter_desc, value_share, qty_share) |>
  pivot_longer(c(value_share, qty_share),
               names_to = "metric", values_to = "share") |>
  mutate(
    metric = recode(metric,
                    value_share = "Share of reported value",
                    qty_share   = "Share of volume (kg)"),
    label = paste0(round(share, 1), "%")
  )

fig_02 <- tidyplot(share_long, x = share, y = reporter_desc, color = metric) |>
  add_data_points(size = 3.5) |>
  add_title("South Africa is the gateway, China the higher-value destination") |>
  add_caption("Share of cumulative 2010-2024 imports. South Africa value uses primary_value; China uses fobvalue because its primary_value is missing on 51 of 91 rows. China pays more per kg than South Africa, signalling a different role in the wool chain.") |>
  adjust_x_axis(limits = c(0, 82)) |>
  adjust_x_axis_title("Share of cumulative imports (%)") |>
  adjust_y_axis_title("") |>
  adjust_font(fontsize = 11, family = font_family) |>
  theme_tidyplot() +
  geom_segment(
    data = reporter_totals,
    inherit.aes = FALSE,
    aes(x = value_share, xend = qty_share,
        y = reporter_desc, yend = reporter_desc),
    color = "grey60", linewidth = 1.1, alpha = 0.8
  ) +
  geom_text(
    data = share_long,
    aes(x = share, label = label),
    hjust = -0.35, size = 3.5
  ) +
  theme(legend.position = "top")

ggsave(file.path(fig_dir, "fig_02_gateway_vs_destination.png"),
       plot = fig_02, width = 8.5, height = 4.5, dpi = 300)

# --- Figure 3: price per kg trend ---------------------------------
fig_03 <- tidyplot(sa_price_trend, x = year, y = price_per_kg) |>
  add_sum_line(linewidth = 0.8) |>
  add_data_points(size = 2.5) |>
  add_title("Wool prices crashed in 2013, dipped in 2020, then plateaued above $6 per kg") |>
  add_caption("Annual average price (USD/kg) reported by South Africa (HS 5101). 2018-19 are partial-reporting years. The 2013 crash follows a wool glut; 2020 shows the COVID dip before the 2021-24 plateau.") |>
  adjust_x_axis(breaks = seq(2010, 2024, 2)) |>
  adjust_y_axis(labels = scales::label_dollar()) |>
  adjust_y_axis_title("USD per kg") |>
  adjust_x_axis_title("Year") |>
  adjust_font(fontsize = 11, family = font_family) |>
  theme_tidyplot() +
  annotate("text", x = 2013, y = 1.4, label = "2013 crash",
           size = 3.5, color = "#C62828", fontface = "bold") +
  annotate("text", x = 2020.4, y = 3.6, label = "COVID dip",
           size = 3.5, color = "#C62828", fontface = "bold") +
  annotate("text", x = 2017.5, y = 6.9,
           label = "Plateau ~$6.5/kg", size = 3.5,
           color = "#2E7D32", fontface = "bold")

ggsave(file.path(fig_dir, "fig_03_price_per_kg_trend.png"),
       plot = fig_03, width = 9.5, height = 4.5, dpi = 300)

# ---- 8. Key numbers for the report --------------------------------

key_numbers <- list(
  sa_value_M   = reporter_totals$value_M[reporter_totals$reporter_desc == "South Africa"],
  china_value_M = reporter_totals$value_M[reporter_totals$reporter_desc == "China"],
  sa_qty_Mkg   = reporter_totals$qty_Mkg[reporter_totals$reporter_desc == "South Africa"],
  china_qty_Mkg = reporter_totals$qty_Mkg[reporter_totals$reporter_desc == "China"],
  sa_price     = reporter_totals$price_per_kg[reporter_totals$reporter_desc == "South Africa"],
  china_price  = reporter_totals$price_per_kg[reporter_totals$reporter_desc == "China"],
  peak_month   = seasonal_profile$month[which.max(seasonal_profile$mean_value_M)],
  trough_month = seasonal_profile$month[which.min(seasonal_profile$mean_value_M)],
  peak_value_M = max(seasonal_profile$mean_value_M),
  trough_value_M = min(seasonal_profile$mean_value_M),
  price_2013   = sa_price_trend$price_per_kg[sa_price_trend$year == 2013],
  price_2024   = sa_price_trend$price_per_kg[sa_price_trend$year == 2024],
  value_2010_M = sa_price_trend$value_M[sa_price_trend$year == 2010],
  value_2024_M = sa_price_trend$value_M[sa_price_trend$year == 2024]
)

cat("\n===== Key numbers =====\n")
print(key_numbers)

cat("\nDone. Figures written to", fig_dir, "and tables to", out_dir, "\n")
