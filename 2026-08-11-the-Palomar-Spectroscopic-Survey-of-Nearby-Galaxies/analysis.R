# ============================================================
# TidyTuesday | 2026-08-11 | Palomar Spectroscopic Survey of
# Nearby Galaxies
#
# Three exploration questions, one shared colour palette:
#   1. BPT     - Can two emission-line ratios separate star-forming
#                nuclei from accreting black holes?
#   2. Hubble  - Does galaxy shape predict what powers its centre?
#   3. Mass    - Do more massive galaxies host more active nuclei?
#
# Data: Ho, Filippenko & Sargent (1995, 1997, 2009), via VizieR.
# NOTE: the survey CSV's "log_*" columns are actually LINEAR
# intensity ratios (they reach ~21); log10() is applied here to
# build the BPT diagram.
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)
library(stringr)

survey  <- read_csv("palomar_survey.csv", show_col_types = FALSE)
emission <- read_csv("palomar_emission_lines.csv", show_col_types = FALSE)

out_dir <- "outputs"
fig_dir <- "figures"
dir.create(out_dir, showWarnings = FALSE)
dir.create(fig_dir, showWarnings = FALSE)

font_family <- "Plus Jakarta Sans"   # falls back to system sans if absent

# ---- 1. Shared palette & factor order ---------------------------

activity_order <- c("H II", "Transition", "Seyfert", "LINER", "Absorption")

palette <- c(
  "H II"       = "#3B82F6",   # blue    - star formation
  "Seyfert"    = "#EF4444",   # red     - luminous AGN
  "LINER"      = "#F59E0B",   # orange  - low-luminosity AGN
  "Transition" = "#10B981",   # green   - composite
  "Absorption" = "#6B7280"    # grey    - featureless
)

# ---- 2. Morphology binning (Hubble sequence) --------------------

morph_bin <- function(t) {
  t <- trimws(t)
  ifelse(grepl("^dE|^E", t), "Elliptical",
  ifelse(grepl("^dS|^S0|^SB0", t), "Lenticular",
  ifelse(grepl("^SB|^RSB", t), "Barred spiral",
  ifelse(grepl("^RS0", t), "Lenticular",
  ifelse(grepl("^RS|^S", t), "Spiral",
  ifelse(grepl("^I", t), "Irregular", "Other"))))))
}

survey <- survey |>
  mutate(
    morphology = morph_bin(hubble_type),
    confidence_alpha = case_when(
      classification_confidence == "confident"      ~ 1.0,
      classification_confidence == "uncertain"      ~ 0.5,
      classification_confidence == "very uncertain" ~ 0.3,
      TRUE ~ 0.9
    )
  )

# The 2 galaxies of ambiguous ("Other") morphology are kept for the
# headline census but excluded from morphology-based figures.
survey_full <- survey
survey      <- survey |> filter(morphology != "Other")

# ---- 3. Figure 1: BPT diagnostic diagram ------------------------
# x = log10([N II]/Ha), y = log10([O III]/Hb), coloured by class.
# Classification-uncertain galaxies are drawn semi-transparent.

bpt <- survey |>
  filter(!is.na(log_nii_ha), !is.na(log_oiii_hb),
         activity_type != "Absorption", !is.na(activity_type)) |>
  mutate(
    x = log10(log_nii_ha),
    y = log10(log_oiii_hb),
    activity_type = factor(activity_type, levels = activity_order)
  )

# Theoretical starburst boundaries (Kewley 2001, Kauffmann 2003).
# Both lines are clipped to the axis window (they run to an
# asymptote), so the steep climb near x ~ 0.05 / 0.47 is what shows.
x_lim <- c(-1.7, 1.0)
y_lim <- c(-1.5, 2.0)

clip_curve <- function(f, x) {
  d <- data.frame(x = x, y = f(x))
  d[is.finite(d$y) & d$y >= y_lim[1] & d$y <= y_lim[2] & d$x >= x_lim[1] & d$x <= x_lim[2], ]
}

kw <- clip_curve(function(x) 1.19 + 0.61 / (x - 0.47), seq(x_lim[1], x_lim[2], 0.005))
kf <- clip_curve(function(x) 1.30 + 0.61 / (x - 0.05), seq(x_lim[1], x_lim[2], 0.005))

fig_01 <- ggplot(bpt, aes(x, y)) +
  geom_point(aes(colour = activity_type, alpha = confidence_alpha),
             size = 1.7, shape = 16) +
  geom_line(data = kf, aes(x, y), colour = "#2563EB",
            linetype = "dashed", linewidth = 0.55) +
  geom_line(data = kw, aes(x, y), colour = "#7C3AED",
            linetype = "dashed", linewidth = 0.55) +
  annotate("text", x = -0.32, y = 1.82, label = "Kauffmann 2003",
           size = 3, colour = "#2563EB", hjust = 0.6) +
  annotate("text", x = 0.35, y = 1.82, label = "Kewley 2001",
           size = 3, colour = "#7C3AED", hjust = 0.6) +
  scale_colour_manual(values = palette, name = NULL) +
  scale_alpha(range = c(0.3, 1), guide = "none") +
  scale_x_continuous(limits = x_lim, breaks = seq(-1.5, 1.0, 0.5)) +
  scale_y_continuous(limits = y_lim, breaks = seq(-1.5, 2.0, 0.5)) +
  labs(
    x = expression("log[NII]/H"*alpha~"   (gas excitation)"),
    y = expression("log[OIII]/H"*beta~"   (ionising power)"),
    title = str_wrap("Two emission-line ratios separate star-forming galaxies from black holes",
                     60),
    caption = "408 nuclei from Ho, Filippenko & Sargent (1997). Dashed lines: theoretical starburst limits — star formation lives below Kauffmann (2003); luminous AGN above Kewley (2001). Faded points carry an uncertain classification."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, family = font_family),
    plot.caption = element_text(hjust = 0, colour = "grey40", size = 9,
                                lineheight = 1.3),
    legend.position = "top",
    legend.text = element_text(size = 10, family = font_family),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "fig_01_bpt_diagram.png"),
       plot = fig_01, width = 8.5, height = 6.5, dpi = 300)

# ---- 4. Figure 2: Hubble-sequence strip -------------------------
# 100% stacked bars along the Hubble sequence: does the centre of a
# galaxy track its shape?

morph_order <- c("Elliptical", "Lenticular", "Spiral",
                 "Barred spiral", "Irregular")

strip <- survey |>
  filter(!is.na(activity_type), activity_type != "Absorption") |>
  count(morphology, activity_type, .drop = FALSE) |>
  group_by(morphology) |>
  mutate(share = n / sum(n) * 100) |>
  ungroup() |>
  mutate(
    morphology = factor(morphology, levels = morph_order),
    activity_type = factor(activity_type, levels = activity_order)
  )

fig_02 <- ggplot(strip, aes(morphology, share, fill = activity_type)) +
  geom_col(width = 0.72, colour = "white", linewidth = 0.3) +
  geom_text(aes(label = ifelse(n > 5, paste0(n), "")),
            position = position_stack(vjust = 0.5), size = 2.6,
            colour = "white", fontface = "bold") +
  scale_fill_manual(values = palette, name = NULL) +
  scale_y_continuous(labels = scales::label_percent(scale = 1)) +
  labs(
    x = NULL,
    y = "Share of galaxies",
    title = str_wrap("Early-type galaxies hide black holes; late types make stars",
                     60),
    caption = "n = number of galaxies in each cell (labelled). Early Hubble types (E, S0) are dominated by LINER/AGN nuclei; late types (Sc, Sm, Im) by star-forming H II nuclei."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, family = font_family),
    plot.caption = element_text(hjust = 0, colour = "grey40", size = 9,
                                lineheight = 1.3),
    legend.position = "top",
    legend.text = element_text(size = 10, family = font_family),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "fig_02_hubble_sequence.png"),
       plot = fig_02, width = 8.5, height = 5.2, dpi = 300)

# ---- 5. Figure 3: mass ladder (velocity dispersion) --------------
# Stellar velocity dispersion sigma ~ black-hole mass (M-sigma).
# More massive galaxies host more energetic nuclei.

ladder <- survey |>
  filter(!is.na(activity_type), activity_type != "Absorption",
         !is.na(velocity_dispersion_km_s)) |>
  mutate(
    activity_type = factor(activity_type,
      levels = c("H II", "Transition", "Seyfert", "LINER"))
  )

sigma_med <- ladder |>
  group_by(activity_type) |>
  summarise(median_sigma = median(velocity_dispersion_km_s), .groups = "drop")

fig_03 <- ggplot(ladder, aes(activity_type, velocity_dispersion_km_s,
                             fill = activity_type)) +
  geom_violin(colour = "grey35", alpha = 0.55, width = 0.9) +
  geom_jitter(aes(alpha = confidence_alpha), width = 0.16, size = 1.1,
              shape = 16, colour = "grey25") +
  geom_point(data = sigma_med, aes(x = activity_type, y = median_sigma),
             shape = 21, size = 3, fill = "white", stroke = 0.9,
             colour = "grey15") +
  geom_text(data = sigma_med,
            aes(x = activity_type, y = median_sigma,
                label = paste0(round(median_sigma), " km/s")),
            nudge_y = 22, size = 3.2, fontface = "bold", colour = "grey25") +
  scale_fill_manual(values = palette, guide = "none") +
  scale_alpha(range = c(0.25, 1), guide = "none") +
  scale_y_log10(labels = scales::label_number()) +
  labs(
    x = NULL,
    y = "Stellar velocity dispersion (km/s)",
    title = str_wrap("The most energetic nuclei sit in the most massive galaxies",
                     60),
    caption = "log scale. sigma traces central black-hole mass via the M-sigma relation. White dots: medians (H II ~70, Transition ~134, Seyfert ~149, LINER ~168 km/s)."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, family = font_family),
    plot.caption = element_text(hjust = 0, colour = "grey40", size = 9,
                                lineheight = 1.3),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "fig_03_mass_ladder.png"),
       plot = fig_03, width = 8.5, height = 5.2, dpi = 300)

# ---- 6. Key numbers for the report -------------------------------

classified <- survey_full |> filter(!is.na(activity_type))

key_numbers <- list(
  n_galaxies        = nrow(survey_full),
  n_emission        = nrow(emission),
  n_bpt             = nrow(bpt),
  n_classified      = nrow(classified),
  n_unclassified    = nrow(survey_full) - nrow(classified),
  n_hii             = sum(classified$activity_type == "H II"),
  n_seyfert         = sum(classified$activity_type == "Seyfert"),
  n_liner           = sum(classified$activity_type == "LINER"),
  n_transition      = sum(classified$activity_type == "Transition"),
  n_agn_strict      = sum(classified$activity_type %in% c("Seyfert", "LINER")),
  n_agn_any         = sum(classified$activity_type %in%
                            c("Seyfert", "LINER", "Transition")),
  sigma_hii         = median(ladder$velocity_dispersion_km_s[ladder$activity_type == "H II"]),
  sigma_seyfert     = median(ladder$velocity_dispersion_km_s[ladder$activity_type == "Seyfert"]),
  sigma_liner       = median(ladder$velocity_dispersion_km_s[ladder$activity_type == "LINER"]),
  sigma_transition  = median(ladder$velocity_dispersion_km_s[ladder$activity_type == "Transition"]),
  bpt_med_seyfert   = median(bpt$y[bpt$activity_type == "Seyfert"]),
  bpt_med_hii       = median(bpt$y[bpt$activity_type == "H II"])
)

ell_liner <- survey |>
  filter(morphology == "Elliptical", !is.na(activity_type)) |>
  summarise(pct = round(100 * sum(activity_type == "LINER") / n()))
spi_hii <- survey |>
  filter(morphology == "Spiral", !is.na(activity_type)) |>
  summarise(pct = round(100 * sum(activity_type == "H II") / n()))

key_numbers$pct_ell_liner <- ell_liner$pct
key_numbers$pct_spi_hii   <- spi_hii$pct

key_df <- tibble(metric = names(key_numbers), value = as.character(unlist(key_numbers)))
write_csv(key_df, file.path(out_dir, "key_numbers.csv"))

class_counts <- survey_full |>
  filter(!is.na(activity_type)) |>
  count(activity_type, name = "Galaxies") |>
  arrange(desc(Galaxies)) |>
  mutate(
    Activity = activity_type,
    `Share of classified` = paste0(round(100 * Galaxies / sum(Galaxies), 1), "%")
  ) |>
  select(Activity, Galaxies, `Share of classified`)
write_csv(class_counts, file.path(out_dir, "classification_counts.csv"))

strip_out <- strip |> select(-share)
write_csv(strip_out, file.path(out_dir, "hubble_strip.csv"))

cat("Done. Figures written to", fig_dir, "\n")
cat("n BPT:", key_numbers$n_bpt, "| classified:", key_numbers$n_classified,
    "| unclassified:", key_numbers$n_unclassified, "\n")
cat("H II:", key_numbers$n_hii, "| Seyfert:", key_numbers$n_seyfert,
    "| LINER:", key_numbers$n_liner, "| Transition:", key_numbers$n_transition, "\n")
