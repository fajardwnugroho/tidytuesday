# ============================================================
# TidyTuesday | 2026-08-04 | Basotho Wool
#
# Two business questions:
#   1. Top importer - Is South Africa the real buyer, or a gateway
#                      for higher-value Chinese demand?
#   2. Trend         - What drives the value of Lesotho's wool trade:
#                      price per kg, or volume exported?
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
library(cowplot)

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
    year  = ref_year
  )

# ---- 3. Data quality ------------------------------------------
# South Africa is the only reporter with near-complete monthly
# coverage; China and India are patchy and Uruguay has 2 rows.

monthly_coverage <- wool |>
  count(reporter_desc, year, name = "months_reported")

write_csv(monthly_coverage, file.path(out_dir, "monthly_coverage.csv"))

# ---- 4. Reporter totals (question 1) --------------------------

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

# ---- 5. South Africa annual trend (question 2) ----------------
# South Africa is the reliable series for trend analysis. Volume
# (kg) is the closest available proxy for the quantity of wool
# leaving Lesotho through the gateway.

sa_price_trend <- wool |>
  filter(reporter_desc == "South Africa") |>
  group_by(year) |>
  summarise(
    price_per_kg    = sum(value, na.rm = TRUE) / sum(qty, na.rm = TRUE),
    value_M         = sum(value, na.rm = TRUE) / 1e6,
    qty_Mkg         = sum(qty, na.rm = TRUE) / 1e6,
    months_reported = n_distinct(month),
    .groups         = "drop"
  ) |>
  mutate(complete_year = months_reported == 12)

write_csv(sa_price_trend, file.path(out_dir, "sa_price_trend.csv"))

# ---- 6. Figures -------------------------------------------------

font_family <- "Plus Jakarta Sans"   # falls back to system sans if absent

# --- Figure 1: gateway vs destination (two-panel bars) -------------
# Panel A: cumulative volume imported (M kg); Panel B: price paid
# (USD/kg). India is dropped from the price panel because its unit
# price ($424/kg) is a data artifact, not an economic signal.

reporter_order <- c("South Africa", "China", "India", "Uruguay")

vol_data <- reporter_totals |>
  mutate(
    reporter_desc = factor(reporter_desc, levels = reporter_order),
    label = paste0(round(qty_Mkg, 1), " M kg")
  )

price_data <- reporter_totals |>
  filter(reporter_desc != "India") |>
  mutate(
    reporter_desc = factor(reporter_desc,
                           levels = setdiff(reporter_order, "India")),
    label = scales::dollar(price_per_kg, accuracy = 0.01)
  )

p_vol <- tidyplot(vol_data, x = reporter_desc, y = qty_Mkg) |>
  add_sum_bar(alpha = 0.85) |>
  add_data_labels(label = "label",
                  fontsize = 8, label_position = "above") |>
  adjust_y_axis(limits = c(0, 78)) |>
  adjust_y_axis_title("Cumulative volume (M kg)") |>
  adjust_x_axis_title("") |>
  adjust_font(fontsize = 11, family = font_family) |>
  theme_tidyplot()

p_price <- tidyplot(price_data, x = reporter_desc, y = price_per_kg) |>
  add_sum_bar(alpha = 0.85) |>
  add_data_labels(label = "label",
                  fontsize = 8, label_position = "above") |>
  adjust_y_axis(limits = c(0, 9)) |>
  adjust_y_axis_title("Price paid (USD per kg)") |>
  adjust_x_axis_title("") |>
  adjust_font(fontsize = 11, family = font_family) |>
  theme_tidyplot()

fig_01 <- plot_grid(
  p_vol, p_price,
  ncol = 1, align = "v", axis = "lr",
  labels = c("A  Volume imported", "B  Price paid")
)

ggsave(file.path(fig_dir, "fig_01_gateway_vs_destination.png"),
       plot = fig_01, width = 8.5, height = 6.5, dpi = 300)

# --- Figure 2: price vs volume trend (dual-axis lines) -------------
# Price (USD/kg) on the left axis, volume (M kg) on the right. The
# shaded years are partial-reporting years (2016, 2018, 2019, 2020)
# where the volume line is understated, not a real collapse.

scale_factor <- max(sa_price_trend$price_per_kg) / max(sa_price_trend$qty_Mkg)
partial_years <- sa_price_trend$year[!sa_price_trend$complete_year]

fig_02 <- ggplot(sa_price_trend, aes(x = year)) +
  annotate("rect",
           xmin = partial_years - 0.35, xmax = partial_years + 0.35,
           ymin = -Inf, ymax = Inf, fill = "grey70", alpha = 0.18) +
  geom_line(aes(y = price_per_kg), color = "#1F77B4", linewidth = 1.1) +
  geom_point(aes(y = price_per_kg), color = "#1F77B4", size = 2.6) +
  geom_line(aes(y = qty_Mkg * scale_factor), color = "#D62728",
            linewidth = 1.1, linetype = "22") +
  geom_point(aes(y = qty_Mkg * scale_factor), color = "#D62728",
             size = 2.6, shape = 17) +
  scale_y_continuous(
    name = "Price (USD per kg)",
    labels = scales::label_dollar(),
    sec.axis = sec_axis(~ . / scale_factor, name = "Volume (M kg)")
  ) +
  scale_x_continuous(breaks = seq(2010, 2024, 2), limits = c(2009.5, 2024.5)) +
  labs(
    title = "Wool prices crashed in 2013, dipped in 2020, and plateaued above $6 per kg",
    caption = "Annual averages reported by South Africa (HS 5101, mirror trade). Grey shading marks partial-reporting years (2016, 2018-20) where volume is understated. Price (blue, left axis); volume (red triangles, right axis)."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16, family = font_family),
    plot.caption = element_text(hjust = 0, color = "grey40", size = 9.5,
                                lineheight = 1.4),
    axis.title.y.left = element_text(color = "#1F77B4", face = "bold"),
    axis.title.y.right = element_text(color = "#D62728", face = "bold"),
    panel.grid.minor = element_blank()
  ) +
  annotate("text", x = 2013.3, y = 1.35, label = "2013 price crash\n(volume kept rising)",
           size = 3.5, color = "#1F77B4", fontface = "bold", hjust = 0) +
  annotate("text", x = 2020.5, y = 3.55, label = "COVID dip",
           size = 3.5, color = "#1F77B4", fontface = "bold", hjust = 0) +
  annotate("text", x = 2017.8, y = 7.05,
           label = "Price plateau ~$6.5/kg (2021-24)",
           size = 3.5, color = "#2E7D32", fontface = "bold", hjust = 0)

ggsave(file.path(fig_dir, "fig_02_price_volume_trend.png"),
       plot = fig_02, width = 9.5, height = 4.8, dpi = 300)

# ---- 7. Key numbers for the report --------------------------------

key_numbers <- list(
  sa_value_M    = reporter_totals$value_M[reporter_totals$reporter_desc == "South Africa"],
  china_value_M = reporter_totals$value_M[reporter_totals$reporter_desc == "China"],
  sa_qty_Mkg    = reporter_totals$qty_Mkg[reporter_totals$reporter_desc == "South Africa"],
  china_qty_Mkg = reporter_totals$qty_Mkg[reporter_totals$reporter_desc == "China"],
  sa_price      = reporter_totals$price_per_kg[reporter_totals$reporter_desc == "South Africa"],
  china_price   = reporter_totals$price_per_kg[reporter_totals$reporter_desc == "China"],
  price_2013    = sa_price_trend$price_per_kg[sa_price_trend$year == 2013],
  price_2024    = sa_price_trend$price_per_kg[sa_price_trend$year == 2024],
  price_2020    = sa_price_trend$price_per_kg[sa_price_trend$year == 2020],
  qty_2010_Mkg  = sa_price_trend$qty_Mkg[sa_price_trend$year == 2010],
  qty_2013_Mkg  = sa_price_trend$qty_Mkg[sa_price_trend$year == 2013],
  qty_2020_Mkg  = sa_price_trend$qty_Mkg[sa_price_trend$year == 2020],
  qty_2024_Mkg  = sa_price_trend$qty_Mkg[sa_price_trend$year == 2024],
  value_2010_M  = sa_price_trend$value_M[sa_price_trend$year == 2010],
  value_2024_M  = sa_price_trend$value_M[sa_price_trend$year == 2024]
)

cat("\n===== Key numbers =====\n")
print(key_numbers)

cat("\nDone. Figures written to", fig_dir, "and tables to", out_dir, "\n")
