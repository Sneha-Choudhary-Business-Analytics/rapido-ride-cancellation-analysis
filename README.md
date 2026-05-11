# 🚖 Ride Cancellation & Revenue Leakage Analysis — Rapido

## 📌 Problem Statement
High ride cancellation rates were causing significant revenue loss. 
This project identifies the root causes and quantifies the impact.

## 🛠️ Tools Used
- SQL — data extraction, cleaning, aggregation
- Power BI — dashboard design, DAX KPIs, heatmaps

## 📊 Dataset
- 750 ride requests analyzed
- Variables: time, distance, pricing, pickup zone, cancellation reason

## 🔍 Key Findings
- 85% rejection rate identified during evening rush hours
- Surge pricing and pickup location = #1 cancellation triggers
- ₹5,130+ recoverable revenue identified per analysis cycle

## 💡 Recommendations
- Adjust driver allocation during evening peak hours
- Review surge pricing thresholds in high-rejection zones

## 📁 Files in this Repository
- `rapido_analysis.sql` — all SQL queries used
- `rapido_dashboard.pbix` — Power BI dashboard file
- `dashboard_screenshot.png` — preview of final dashboard
