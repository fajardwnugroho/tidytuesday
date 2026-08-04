# Basotho Wool: The Seasonal Rhythm of Lesotho's Most Valuable Export

> A business-oriented TidyTuesday analysis (2026-08-04) of Lesotho's wool trade,
> using UN Comtrade mirror-trade data. The question at the heart of it: *when* does
> the money flow, *who* really buys, and *what* moves the price?

## Dataset

- **TidyTuesday** 2026-08-04, curated by [Ntobeko Sosibo](https://github.com/afrikaniz3d-za).
- **Original source:** [UN Comtrade Database](https://comtradeplus.un.org/) — monthly
  imports of Lesotho wool (HS 5101) recorded by reporting partners, 2010-2024.
- **Background:** *"The mountain men behind Lesotho's wool wealth"* by Sechaba
  Mokhethi, [GroundUp News](https://groundup.org.za/article/the-mountain-men-behind-lesothos-wool-wealth/).
- **Files:** `data/basotho_wool.csv`, `analysis.R`, `report.qmd`, `figures/`, `outputs/`.

## Business Questions

1. **Seasonality** — When does Basotho wool export revenue trough and peak? Is the
   low season really *winter*, or does it start earlier?
2. **Top importer** — Is South Africa the true buyer, or a *gateway* for
   higher-value demand from China?
3. **Trend** — How has the price per kilogram moved from 2010 to 2024?

## Methodology

- HS 5101 only (2 rows of waste wool dropped). Mirror-trade imports, USD.
- Value backbone: `primary_value`, falling back to `fobvalue` where China's primary
  value is missing (51/91 rows).
- Seasonality restricted to **South Africa on complete years** (2010-15, 2017,
  2021-24), the only reporter with reliable monthly coverage.
- Full pipeline in `analysis.R`; rendered report in `report.qmd`.

## Key Findings

### 1. The low season runs autumn to winter, not winter alone

![Seasonal profile](figures/fig_01_seasonal_profile.png)

*Alt text: Line and ribbon chart of the mean monthly value of Basotho wool imports
reported by South Africa across 11 complete years. Value is high in January ($2.8M),
falls to a trough of about $0.17M in April, stays below $0.4M through August (the
shaded winter window), then surges to a November peak of $4.6M.*

Revenue follows a steep seasonal curve: **Jan $2.8M → Apr trough $0.2M → flat
Apr-Aug → Oct-Nov peak $4.6M**. The quiet period starts in **autumn (April)**, not
winter — it matches the industry calendar (spring shearing, winter gathering, and
Port Elizabeth auctions in spring/summer). Cash-flow is tightest from **April to
August**, exactly when financing is most needed.

### 2. South Africa is the gateway; China is the high-value destination

![Gateway vs destination](figures/fig_02_gateway_vs_destination.png)

*Alt text: Dumbbell chart of each importer's share of cumulative value vs volume.
South Africa holds 60% of reported value but 72% of volume; China holds 37% of value
but 28% of volume and pays about $7.16/kg versus South Africa's $4.47.*

South Africa is not the end customer — wool is auctioned in **Port Elizabeth** before
re-export. Its 72% of volume at the *lowest* price per kg ($4.47) marks it as the
**gateway**. China's 24M kg arrives at a **60% higher price** ($7.16/kg), the real
signal of demand for quality fibre.

### 3. Prices crashed in 2013 and plateaued above $6/kg

![Price per kg trend](figures/fig_03_price_per_kg_trend.png)

*Alt text: Line chart of the annual average price of Basotho wool (South Africa)
2010-2024. Price falls to a 2013 low of $1.12/kg, recovers to ~$6 by 2017, dips to
$4.04 in COVID 2020, then plateaus at $6.4-6.6 through 2024. Export value grew from
$4M (2010) to ~$38M (2024).*

Price is the dominant lever: a $6.5 → $4 fall would erase roughly **$150M of export
value** at current volumes. The post-2020 plateau is worth protecting via quality
certification and auction positioning.

## Recommendations

1. **Finance the trough** — seasonal working-capital lines for herders and traders
   covering April-August, when auction receipts are three months away.
2. **Track China, not just South Africa** — monitor Chinese import volumes and
   Port Elizabeth auction prices as the leading demand indicators.
3. **Defend the price premium** — quality testing and certification underpin the
   difference between $4.5 and $7/kg.
4. **Harden the data** — China's primary value is 51% missing and non-SA reporting
   is patchy; consistent CIF/FOB conventions would improve comparisons.

## Reproducibility

```r
source("analysis.R")   # regenerates outputs/ and figures/
```

- `analysis.R` — cleaning, summary tables (`outputs/`), and three figures (`figures/`).
- `report.qmd` — the full rendered report (needs Quarto).
- Data: `data/basotho_wool.csv`.

## Data Credit

Dataset: TidyTuesday (2026-08-04). Original source: UN Comtrade Database. Article:
GroundUp News. This dataset is not my own; it is used under the TidyTuesday open-data
ethos. Alt text and figures are my own work.
