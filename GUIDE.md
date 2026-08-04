# TidyTuesday Playbook

**Version 1.0**

> A personal workflow for creating reproducible analytics projects, improving technical skills, and building a consulting-focused portfolio through #TidyTuesday.

------------------------------------------------------------------------

# Purpose

TidyTuesday is not just about creating beautiful charts.

For me, every TidyTuesday project is an opportunity to demonstrate my ability to:

- Understand a business problem
- Explore real-world datasets
- Create reproducible analysis
- Communicate insights clearly
- Deliver business recommendations
- Build a public portfolio

Every project should be something I would be proud to show to a potential client or employer.

------------------------------------------------------------------------

# Success Criteria

Each TidyTuesday project should answer:

- Can someone reproduce my work?
- Does the visualization tell a story?
- Did I generate actionable insights?
- Would this project strengthen my portfolio?
- Could this be presented to a client?

------------------------------------------------------------------------

# Weekly Workflow

```         
Dataset
    ↓
Understand the Data
    ↓
Business Questions
    ↓
Data Cleaning
    ↓
Exploratory Analysis
    ↓
Visualization
    ↓
Business Insights
    ↓
Recommendations
    ↓
GitHub
    ↓
Social Media
```

------------------------------------------------------------------------

# Step 1 — Read the Weekly Dataset

Visit:

<https://github.com/rfordatascience/tidytuesday>

Read:

- README
- Data dictionary
- Original article
- Original data source

Do NOT start coding immediately.

First understand:

- What is this dataset about?
- Why was it collected?
- Who would use this information?
- What business decisions could it support?

------------------------------------------------------------------------

# Step 2 — Define Business Questions

Before writing any code, write 3–5 business questions.

Examples:

- Which categories dominate?
- How has the trend changed over time?
- Which regions perform best?
- Are there unusual observations?
- Which segment contributes the most?

The goal is to answer questions, not simply produce charts.

------------------------------------------------------------------------

# Step 3 — Create Project Structure

```         
tidytuesday/

└── 2026-08-04-basotho-wool/
    ├── README.md
    ├── analysis.R
    ├── report.qmd
    ├── figures/
    ├── data/
    ├── app/              # optional
    └── outputs/
```

------------------------------------------------------------------------

# Step 4 — Data Preparation

Tasks:

- Import data
- Check missing values
- Validate data types
- Rename variables if needed
- Create derived variables
- Document assumptions

Keep the cleaning process reproducible.

Never edit raw data manually.

------------------------------------------------------------------------

# Step 5 — Exploratory Data Analysis

Questions to ask:

- What does each variable represent?
- Are there outliers?
- Are there trends?
- Are there patterns?
- Which variables matter most?

Don't worry about aesthetics yet.

Focus on understanding.

------------------------------------------------------------------------

# Step 6 — Design the Story

Every visualization should answer one question.

Instead of:

"I made a bar chart."

Think:

"This chart demonstrates..."

Every chart needs a purpose.

------------------------------------------------------------------------

# Step 7 — Create Visualizations

Preferred characteristics:

✓ Clear

✓ Minimal

✓ Readable

✓ Accessible

Avoid:

- unnecessary colors
- chart junk
- 3D charts
- tiny labels
- rainbow palettes

Ask:

Would an executive understand this within 15 seconds?

------------------------------------------------------------------------

# Step 8 — Write Business Insights

For every visualization, write:

## Observation

What happened?

## Interpretation

Why did it happen?

## Business Impact

Why should someone care?

Example:

Observation

Exports increased by 40% between 2015 and 2020.

Interpretation

Demand from neighboring countries grew steadily.

Business Impact

Companies may need to increase production capacity.

------------------------------------------------------------------------

# Step 9 — Write Recommendations

Always finish with recommendations.

Template:

Current Situation

↓

Evidence

↓

Recommendation

↓

Expected Outcome

Example:

Export destinations are highly concentrated.

↓

Most exports go to one country.

↓

Diversify export markets.

↓

Reduce dependency risk.

------------------------------------------------------------------------

# Step 10 — Build GitHub Repository

Repository should include:

- README
- Source code
- Figures
- Report
- Dataset link
- License (optional)

README structure:

# Project

## Dataset

## Business Questions

## Methodology

## Key Findings

## Recommendations

## Reproducibility

------------------------------------------------------------------------

# Step 11 — (Optional) Build a Shiny App

Only if it adds value.

Possible features:

- filters
- interactive plots
- drill-down
- maps
- KPI cards

Remember:

Interactivity should improve understanding.

------------------------------------------------------------------------

# Step 12 — Publish on Social Media

Recommended structure:

Hook

↓

Context

↓

Three key findings

↓

Business recommendation

↓

Visualization

↓

GitHub link

↓

Dataset credit

↓

Hashtags

Example hashtags:

#TidyTuesday

#RStats

#DataVisualization

#Analytics

#BusinessAnalytics

------------------------------------------------------------------------

# Step 13 — Add Alt Text

Every visualization should include accessibility text.

Formula:

Chart type

↓

Data shown

↓

Main takeaway

Example:

"Horizontal bar chart showing export values by destination country. South Africa receives the largest share of exports, indicating strong market concentration."

------------------------------------------------------------------------

# Step 14 — Credit the Data Source

Always include:

Dataset: TidyTuesday

Original Source: (original source)

GitHub: (repository)

Never claim ownership of the dataset.

------------------------------------------------------------------------

# Step 15 — Reflect

After publishing, answer:

What did I learn?

What would I improve?

What new technique did I practice?

What would I do differently?

Learning is more important than perfection.

------------------------------------------------------------------------

# Community Guidelines

Always:

✓ Be respectful

✓ Credit the data source

✓ Share your code

✓ Use #TidyTuesday

✓ Include visualization

✓ Include alt text

✓ Encourage others

Never:

✗ Criticize the dataset

✗ Attack other participants

✗ Manipulate data without explanation

✗ Remove attribution

------------------------------------------------------------------------

# Personal Quality Checklist

Before publishing, ask:

## Business

- Does this answer a meaningful question?
- Are recommendations actionable?

## Technical

- Is the code reproducible?
- Is the repository organized?
- Is everything documented?

## Visualization

- Is it easy to understand?
- Does every chart have a purpose?

## Communication

- Is the story clear?
- Would a non-technical audience understand it?

## Accessibility

- Alt text included
- Labels readable
- Good color contrast

------------------------------------------------------------------------

# My Personal Goal

I do not participate in #TidyTuesday simply to create visualizations.

I participate to become a better analytics engineer, data storyteller, and business consultant.

Every project should become a portfolio piece that demonstrates how I transform data into business decisions.
