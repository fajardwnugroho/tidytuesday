# ============================================================
# TidyTuesday | 2026-08-18 | IELTS exam results
#
# Four exploration questions, one shared colour palette:
#   1. Parts  - Which test part is hardest? (writing, for most)
#   2. Ladder - Do native English speakers top their own test?
#   3. Bands  - Why not? Band distributions, German vs English
#               vs Arabic.
#   4. Reasons- Does the reason for sitting the test predict the
#               score?
#
# Data: IELTS official test statistics (ielts.org), years
# 2022-2023 / 2023-2024 / 2024-2025. Aggregated means and
# band distributions by language, nationality and reason.
# NOTE: the "percent" columns are proportions (0-1), not
# percentages; and one language appears twice in the source
# ("Ibo/lgbo" and "Ibo/Igbo" - merged here).
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)
library(stringr)

perf_lang   <- read_csv("performance_by_first_language.csv", show_col_types = FALSE)
perf_nat    <- read_csv("performance_by_nationality.csv",   show_col_types = FALSE)
demo_lang   <- read_csv("demo_by_first_language.csv",       show_col_types = FALSE)
demo_nat    <- read_csv("demo_by_nationality.csv",          show_col_types = FALSE)
demo_reason <- read_csv("demo_by_reasons.csv",              show_col_types = FALSE)

out_dir <- "outputs"
fig_dir <- "figures"
dir.create(out_dir, showWarnings = FALSE)
dir.create(fig_dir, showWarnings = FALSE)

font_family <- "Plus Jakarta Sans"   # falls back to system sans if absent

# ---- 1. Shared palette ------------------------------------------

col_english <- "#D62728"   # red    - native speakers
col_german  <- "#1F4E79"   # navy   - top-scoring language
col_arabic  <- "#E8A33D"   # amber  - lower-scoring language
col_other   <- "#9AA5B1"   # grey   - everyone else
col_academic <- "#1F4E79"  # navy   - Academic module
col_gt       <- "#E67E22"  # orange - General Training module

# ---- 2. Tidy: bands to numbers, merge the Ibo duplicate ---------

band_num <- c(
  "<4" = 3.5, "4" = 4, "4.5" = 4.5, "5" = 5, "5.5" = 5.5,
  "6" = 6, "6.5" = 6.5, "7" = 7, "7.5" = 7.5,
  "8" = 8, "8.5" = 8.5, "9" = 9
)

merge_ibo <- function(x) ifelse(x == "Ibo/lgbo", "Ibo/Igbo", x)

perf_lang <- perf_lang |> mutate(language = merge_ibo(language))
demo_lang <- demo_lang |> mutate(language = merge_ibo(language))

demo_lang$band_val <- band_num[demo_lang$band]
demo_nat$band_val  <- band_num[demo_nat$band]
demo_reason$band_val <- band_num[demo_reason$band]

# ---- 3. Key numbers ----------------------------------------------

overall_acad <- perf_lang |>
  filter(type == "Academic", part == "overall") |>
  group_by(language) |>
  summarise(score = mean(score), .groups = "drop")

ladder_all <- overall_acad |>
  arrange(desc(score)) |>
  mutate(rank = row_number())

english_rank <- ladder_all$rank[ladder_all$language == "English"]
english_score <- ladder_all$score[ladder_all$language == "English"]
german_score  <- ladder_all$score[ladder_all$language == "German"]

part_profile <- perf_lang |>
  group_by(type, part) |>
  summarise(score = mean(score), .groups = "drop")

acad_prof <- part_profile |>
  filter(type == "Academic") |>
  arrange(score)
acad_order <- acad_prof$part

writing_share <- perf_lang |>
  filter(type == "Academic", part %in% c("listening", "reading", "writing", "speaking")) |>
  group_by(language, part) |>
  summarise(score = mean(score), .groups = "drop") |>
  tidyr::pivot_wider(names_from = part, values_from = score) |>
  mutate(writing_lowest = writing == pmin(listening, reading, writing, speaking))

pct_writing_worst <- round(100 * mean(writing_share$writing_lowest))

# Reason -> score: weighted mean band from the demo distribution
reason_scores <- demo_reason |>
  filter(type == "Academic") |>
  group_by(reason) |>
  summarise(score = sum(percent * band_val) / sum(percent), .groups = "drop") |>
  arrange(desc(score)) |>
  mutate(category = case_when(
    grepl("doctor|dentist|nurse", reason, ignore.case = TRUE)  ~ "Medical registration",
    grepl("registration", reason, ignore.case = TRUE)          ~ "Professional",
    grepl("immigration", reason, ignore.case = TRUE)           ~ "Immigration",
    grepl("employment", reason, ignore.case = TRUE)            ~ "Employment",
    grepl("education", reason, ignore.case = TRUE)             ~ "Education",
    TRUE                                                        ~ "Other"
  ))

reason_top <- reason_scores$score[1]
reason_bot <- reason_scores$score[nrow(reason_scores)]

japanese_score <- ladder_all$score[ladder_all$language == "Japanese"]
arabic_score   <- ladder_all$score[ladder_all$language == "Arabic"]

year_trend <- perf_lang |>
  filter(part == "overall", type == "Academic") |>
  group_by(year) |>
  summarise(score = mean(score), .groups = "drop")

key_numbers <- data.frame(
  metric = c("languages", "nationalities", "german_score", "english_score",
             "english_rank", "pct_writing_worst", "writing_mean_acad",
             "listening_mean_acad", "acad_overall", "gt_overall",
             "reason_top_score", "reason_top_name",
             "reason_bot_score", "reason_bot_name",
             "acad_year_min", "acad_year_max", "japanese_score",
             "arabic_score", "gt_reading_mean", "gt_writing_mean",
             "n_bands"),
  value = c(nrow(ladder_all), length(unique(perf_nat$nationality)),
            round(german_score, 2), round(english_score, 2),
            english_rank, pct_writing_worst,
            round(part_profile$score[part_profile$type == "Academic" &
                                    part_profile$part == "writing"], 2),
            round(part_profile$score[part_profile$type == "Academic" &
                                    part_profile$part == "listening"], 2),
            round(mean(overall_acad$score), 2),
            round(perf_lang$score[perf_lang$type == "General_Training" &
                                 perf_lang$part == "overall"] |> mean(), 2),
            round(reason_scores$score[1], 2), reason_scores$reason[1],
            round(reason_scores$score[nrow(reason_scores)], 2),
            reason_scores$reason[nrow(reason_scores)],
            round(min(year_trend$score), 2), round(max(year_trend$score), 2),
            round(japanese_score, 2), round(arabic_score, 2),
            round(part_profile$score[part_profile$type == "General_Training" &
                                    part_profile$part == "reading"], 2),
            round(part_profile$score[part_profile$type == "General_Training" &
                                    part_profile$part == "writing"], 2),
            length(band_num))
)
write_csv(key_numbers, file.path(out_dir, "key_numbers.csv"))
write_csv(part_profile,    file.path(out_dir, "part_profiles.csv"))
write_csv(ladder_all,      file.path(out_dir, "language_ladder.csv"))
write_csv(reason_scores,   file.path(out_dir, "reason_scores.csv"))

# ---- 4. Figure 1: part profiles (Academic vs General Training) ---
# Mean band by test part. Writing is the low point of the Academic
# module for most language groups.

prof_plot <- part_profile |>
  mutate(part = factor(part, levels = c(acad_order, setdiff(unique(part), acad_order)))) |>
  filter(part %in% acad_order)

fig_01 <- ggplot(prof_plot, aes(part, score, colour = type, group = type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3.2) +
  geom_text(aes(label = sprintf("%.2f", score)),
            vjust = -1.1, size = 3.2, show.legend = FALSE, fontface = "bold") +
  scale_colour_manual(values = c("Academic" = col_academic, "General_Training" = col_gt),
                      name = NULL,
                      labels = c("Academic", "General Training")) +
  scale_y_continuous(limits = c(5.8, 6.9), breaks = seq(5.8, 6.9, 0.2)) +
  labs(
    x = NULL,
    y = "Mean band score (all language groups)",
    title = str_wrap("Writing is the wall of the Academic module", 60),
    caption = str_wrap(
      paste0("Mean of language-group averages over the three year cohorts. In Academic, writing is the weakest part for ~",
             pct_writing_worst, "% of language groups; in General Training, reading and writing tie as hardest."),
      95)
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

ggsave(file.path(fig_dir, "fig_01_part_profiles.png"),
       plot = fig_01, width = 8.5, height = 5.5, dpi = 300)

# ---- 5. Figure 2: language ladder ---------------------------------
# All language groups by Academic overall score. Native English
# speakers are only 4th; German speakers are first.

ladder_plot <- ladder_all |>
  mutate(
    highlight = case_when(
      language == "English" ~ "English",
      language == "German"  ~ "German",
      TRUE ~ "Other"
    )
  )

fig_02 <- ggplot(ladder_plot, aes(reorder(language, score), score)) +
  geom_segment(aes(xend = language, yend = 5.6, colour = highlight),
               linewidth = 0.7, alpha = 0.85) +
  geom_point(aes(colour = highlight), size = 2.2) +
  annotate("text", x = "German", y = 7.72, label = "7.61",
           colour = col_german, size = 3.4, fontface = "bold") +
  annotate("text", x = "English", y = 7.05, label = "6.93",
           colour = col_english, size = 3.4, fontface = "bold") +
  scale_colour_manual(
    values = c("English" = col_english, "German" = col_german, "Other" = col_other),
    name = NULL, breaks = c("German", "English"),
    labels = c("German (top)", "English (native)")
  ) +
  scale_y_continuous(limits = c(5.6, 7.85), breaks = seq(5.5, 7.5, 0.5)) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Mean overall band (Academic)",
    title = str_wrap("Native English speakers are not the top of their own test", 58),
    caption = str_wrap(
      "Mean overall score by native language, pooled over 2022-2025 cohorts. German speakers average 7.61; English speakers 6.93 - 4th. Japanese and Arabic groups sit at the bottom.",
      100)
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, family = font_family),
    plot.caption = element_text(hjust = 0, colour = "grey40", size = 9,
                                lineheight = 1.3),
    legend.position = "top",
    legend.text = element_text(size = 10, family = font_family),
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 8, family = font_family)
  )

ggsave(file.path(fig_dir, "fig_02_language_ladder.png"),
       plot = fig_02, width = 8.5, height = 7, dpi = 300)

# ---- 6. Figure 3: band distributions ------------------------------
# German / English / Arabic band distributions (Academic). Germans
# bunch at band 8; English speakers spread around 7-8; Arabic
# speakers skew low.

band_compare <- demo_lang |>
  filter(type == "Academic", language %in% c("German", "English", "Arabic")) |>
  group_by(language, band, band_val) |>
  summarise(percent = mean(percent) * 100, .groups = "drop") |>
  mutate(language = factor(language, levels = c("German", "English", "Arabic")))

band_labs <- c("German" = sprintf("German  (mean %.2f)",
                 round(sum(band_compare$percent[band_compare$language == "German"] *
                           band_compare$band_val[band_compare$language == "German"]) / 100, 2)),
               "English" = sprintf("English  (mean %.2f)",
                 round(sum(band_compare$percent[band_compare$language == "English"] *
                           band_compare$band_val[band_compare$language == "English"]) / 100, 2)),
               "Arabic" = sprintf("Arabic  (mean %.2f)",
                 round(sum(band_compare$percent[band_compare$language == "Arabic"] *
                           band_compare$band_val[band_compare$language == "Arabic"]) / 100, 2)))

fig_03 <- ggplot(band_compare, aes(band_val, percent, fill = language)) +
  geom_area(alpha = 0.45, position = "identity", colour = NA) +
  geom_line(linewidth = 0.9, colour = "white") +
  scale_fill_manual(values = c("German" = col_german, "English" = col_english,
                               "Arabic" = col_arabic),
                    name = NULL, labels = band_labs) +
  scale_x_continuous(breaks = c(4, 5, 6, 7, 8, 9), limits = c(3.5, 9)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    x = "Band score",
    y = "Share of test takers",
    title = str_wrap("Germans bunch at band 8; English speakers spread lower", 56),
    caption = str_wrap(
      "Overall-band distribution, Academic module, pooled 2022-2025. German speakers cluster near band 8; English speakers are spread across 6.5-8.5; Arabic speakers peak around 5.5.",
      100)
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

ggsave(file.path(fig_dir, "fig_03_band_distributions.png"),
       plot = fig_03, width = 8.5, height = 5.5, dpi = 300)

# ---- 7. Figure 4: reason -> score ----------------------------------
# Weighted mean overall band by stated reason for sitting the test.

cat_colours <- c(
  "Medical registration" = "#D62728",
  "Professional"         = "#8C8C8C",
  "Employment"           = "#9AA5B1",
  "Immigration"          = "#E8A33D",
  "Education"            = "#1F4E79",
  "Other"                = "#B0BEC5"
)

acad_mean <- mean(overall_acad$score)

reason_plot <- reason_scores |>
  mutate(reason_short = str_wrap(str_to_title(reason), 42)) |>
  mutate(reason_short = factor(reason_short, levels = rev(reason_short)))

fig_04 <- ggplot(reason_plot, aes(reason_short, score, fill = category)) +
  geom_col(width = 0.72) +
  geom_text(aes(label = sprintf("%.2f", score)),
            hjust = -0.15, size = 3.1, fontface = "bold") +
  geom_hline(yintercept = acad_mean, linetype = "dashed", colour = "grey45") +
  annotate("text", x = 1, y = acad_mean + 0.06, label = "all test takers 6.47",
           colour = "grey35", size = 3, hjust = 0) +
  scale_fill_manual(values = cat_colours, name = "Stated reason") +
  scale_y_continuous(limits = c(0, 7.6), breaks = seq(0, 7, 1)) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Weighted mean overall band (Academic)",
    title = str_wrap("Doctors and dentists score highest - short courses lowest", 56),
    caption = str_wrap(
      "Mean overall band derived from each reason cohort's band distribution, pooled 2022-2025. Medical registration cohorts score highest; short higher-education courses score lowest.",
      100)
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 15, family = font_family),
    plot.caption = element_text(hjust = 0, colour = "grey40", size = 9,
                                lineheight = 1.3),
    legend.position = "top",
    legend.text = element_text(size = 9, family = font_family),
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(size = 8.5, family = font_family)
  )

ggsave(file.path(fig_dir, "fig_04_reason_scores.png"),
       plot = fig_04, width = 8.5, height = 6, dpi = 300)

cat("Done. Figures written to ", fig_dir, "\n", sep = "")
