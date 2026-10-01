# Dashboard Design Specification

## Dashboard Objective

The objective of this dashboard is to provide executive leadership with a comprehensive view of order fulfillment performance, delivery reliability, customer satisfaction impact, and revenue exposure. The dashboard is designed to support operational decision-making by transforming analytical findings into interactive business intelligence.

Rather than presenting operational logs, the dashboard focuses on answering executive-level business questions through clear KPIs, funnel analysis, timing breakdowns, and geographic performance comparisons.

---

# Target Audience

Primary Users

* Chief Operating Officer (COO)
* VP of Operations
* VP of Customer Experience
* Head of Logistics
* Supply Chain Managers
* Business Analysts

Secondary Users

* Customer Success Teams
* Marketplace Operations Teams
* Executive Leadership (CEO, CCO)

---

# Business Questions

The dashboard should enable leadership to answer the following questions:

* How efficiently are orders progressing through the fulfillment funnel?
* Where are the largest bottlenecks in the order journey?
* What percentage of deliveries arrive late, and what is the revenue impact?
* How does delivery performance vary across geographic regions?
* How does fulfillment speed affect customer satisfaction and review scores?
* Which operational improvements would generate the highest business impact?

---

# Data Model

## Primary Data Source

All dashboard visuals connect to a single analytical table:

* **order_fulfillment_funnel_mart** — Order-grain table (one row per order, 51 columns)

## Power BI Relationships

Since the mart is a fully denormalized order-grain table, no relationships are required for the core dashboard. All dimensions (geography, time, segments, flags) are embedded within the mart.

If the dashboard is extended to include cross-case analysis:

* Connect to **customer_retention_mart** via `customer_unique_id` (Many-to-One)
* Connect to **customer_segmentation_mart** via `customer_unique_id` (Many-to-One)
* Connect to **marketing_roi_mart** via `customer_unique_id` (Many-to-One)

## Power BI Import Notes

* Import `order_fulfillment_funnel_mart` as a single table in Import mode
* Create a separate Date table from the full date range covering `order_purchase_timestamp` (e.g., using `CALENDAR` or `CALENDARAUTO` in DAX) to provide daily granularity and full compatibility with Power BI time intelligence functions (Year-over-Year, Month-over-Month)
* Mark the Date table as a Date Table in Power BI and relate it to the mart via the date portion of `order_purchase_timestamp`
* Set `order_id` as the primary key (unique identifier per row)
* Set data types: flags as Whole Number, timestamps as Date/Time, monetary values as Decimal Number, text bands as Text

---

# Dashboard Structure

## Page 1 — Funnel Overview

Purpose

Provide an immediate snapshot of order journey health and funnel progression.

KPIs

* Total Orders
* End-to-End Delivery Rate
* Average Fulfillment Days
* Late Delivery Rate
* Average Review Score
* SLA Compliance Rate

Visuals

* KPI Cards (top row)
* Funnel Chart — Stage counts (Created, Approved, Shipped, Delivered, Reviewed)
* Monthly Order Volume Trend — Line + Bar combo (orders and revenue by month)
* Orders by Current Funnel Stage — Donut chart showing completion vs. stuck orders
* Funnel by Order Status — Stacked bar mapping order statuses to funnel progression

Business Question

How effectively are orders progressing through the fulfillment journey?

---

## Page 2 — Fulfillment Performance

Purpose

Measure fulfillment timing at each stage to identify operational bottlenecks.

KPIs

* Average Approval Hours
* Average Processing Days
* Average Delivery Days
* Average Total Fulfillment Days

Visuals

* Timing Breakdown — Stacked column chart showing time consumed at each stage (approval, processing, transit)
* Monthly Fulfillment Trend — Line chart tracking fulfillment days and late delivery rate over time
* Speed Band Distribution — Grouped bar chart showing Fast/Medium/Slow for approval, shipping, and fulfillment
* Fulfillment by State Map — Filled map with avg fulfillment days as color intensity

Business Question

Which fulfillment stages consume the most time, and where are improvements needed?

---

## Page 3 — Delivery Experience

Purpose

Evaluate delivery reliability and its impact on customer satisfaction.

KPIs

* On-Time Delivery Rate
* Early Delivery Rate
* Late Delivery Rate
* Average Delivery Delay Days

Visuals

* Delivery Performance Distribution — Donut chart (Early / On Time / Late / Not Delivered)
* Review Score by Delivery Performance — Grouped bar showing review band distribution per delivery outcome
* SLA Compliance by State — Sorted bar chart with overall average reference line
* Delivery Efficiency Score Summary — Stacked bar showing Excellent / Good / Needs Improvement / Poor
* Late Delivery Impact — Side-by-side comparison of review scores for late vs. on-time orders

Business Question

How does delivery timeliness affect customer satisfaction?

---

## Page 4 — Business Impact

Purpose

Quantify the revenue impact of fulfillment performance and prioritize operational investments.

KPIs

* Total Revenue
* Revenue from On-Time Orders
* Revenue at Risk (Late Orders)
* Scenario-Based Revenue Uplift (hypothetical 5% / 10% / 20% improvement scenarios)

Visuals

* Revenue by Delivery Performance — Treemap showing revenue concentration by delivery outcome
* Revenue by Order Value Band — Bar chart with dual axis (revenue bars, late delivery rate line)
* Priority States for Improvement — Scatter plot (X: late delivery rate, Y: revenue, bubble size: order count)
* Strategic Investment Matrix — Heatmap (delivery efficiency score vs. order value band, shaded by revenue)

Business Question

Where should operational investment be directed for maximum revenue impact?

---

## Page 5 — Executive Insights

Purpose

Translate analytical findings into actionable business decisions for leadership.

Visual Components

* Executive Summary — Key metrics and trend indicators
* Key Findings — Top 5 analytical insights from Case 04
* Strategic Recommendations — Priority-ranked improvement initiatives
* Priority Matrix — Investment vs. impact positioning of recommendations

Business Question

What actions should leadership take next to improve fulfillment performance?

---

# Global Filters

The dashboard should support interactive filtering by:

* Purchase Year
* Purchase Quarter
* Purchase Month
* Customer State
* Order Status
* Delivery Performance
* SLA Status
* Order Value Band
* Order Size Category
* Primary Payment Type
* Fulfillment Speed Band

All dashboard pages should respond dynamically to selected filters.

---

# Design Principles

The dashboard should emphasize clarity and executive usability rather than visual complexity.

Guiding principles include:

* Minimal visual clutter
* Consistent color palette — Green (Early/On Time), Orange (Late), Grey (Not Delivered) across all pages
* Clear KPI hierarchy
* Interactive drill-down capability (click any state, month, or segment to drill into order detail)
* Executive-first storytelling
* Consistent navigation across pages
* Tooltips with context — every visual tooltip should include order count, revenue, and the primary metric
* Mobile-responsive layout — KPI cards stack vertically on narrow screens

---

# Expected Business Outcomes

The completed dashboard should enable leadership to:

* Monitor end-to-end fulfillment funnel health
* Identify bottleneck stages consuming the most time
* Evaluate delivery performance and SLA compliance
* Quantify revenue at risk from late deliveries
* Compare geographic fulfillment performance
* Prioritize operational improvement investments
* Track the impact of fulfillment initiatives on customer satisfaction

The dashboard should function as a decision-support system rather than a reporting interface.

---

# Deliverables

The final Power BI solution will include:

* Interactive Executive Dashboard
* Five Business Intelligence Pages
* Executive KPI Cards
* Funnel Progression Analysis
* Fulfillment Timing Analysis
* Delivery Performance and Customer Satisfaction Analysis
* Revenue Impact and Strategic Prioritization
* Executive Insights Page

This dashboard represents the visual component of Case 04 and serves as the primary interface through which business stakeholders consume the analytical findings generated throughout the order fulfillment investigation.
