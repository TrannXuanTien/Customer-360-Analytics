# Customer 360 RFM Analysis

A comprehensive SQL-based customer segmentation analysis using RFM (Recency, Frequency, Monetary) methodology to understand customer behavior and value.

## Overview

This project implements a complete RFM analysis pipeline that segments customers based on their transaction patterns. The RFM model is a proven method for customer segmentation that analyzes:

- **Recency (R)**: How recently a customer made a purchase
- **Frequency (F)**: How often a customer makes purchases  
- **Monetary (M)**: How much money a customer spends

## Database Schema

The analysis expects two main tables:

### `customer_registered`
- `ID`: Customer identifier
- `create_date`: Customer registration date
- `stopdate`: Customer churn date (nullable)

### `customer_transaction`
- `customerID`: Foreign key to customer_registered.ID
- `purchase_date`: Date of transaction
- `GMV`: Gross Merchandise Value (transaction amount)

## Features

- **Data Cleaning**: Handles null values and date formatting
- **Quartile-Based Scoring**: Uses percentile ranking for objective segmentation
- **Temporal Analysis**: Accounts for customer lifetime and active periods
- **Scalable Segmentation**: Creates 64 possible RFM combinations (4×4×4)
- **Results Summary**: Provides customer count per RFM segment

## How It Works

### 1. Data Preparation
```sql
-- Clean stopdate field
UPDATE customer_registered SET stopdate = NULL WHERE stopdate = '';

-- Ensure proper datetime formatting
ALTER TABLE customer_registered MODIFY COLUMN stopdate datetime null;
ALTER TABLE customer_registered MODIFY COLUMN create_date datetime;
ALTER TABLE customer_transaction MODIFY COLUMN purchase_date datetime;
```

### 2. Recency Calculation
- Calculates days since last purchase (reference date: 2022-09-01)
- Ranks customers into quartiles (1-4 scale, higher = more recent)

### 3. Frequency Calculation
- Computes average monthly purchase frequency
- Adjusts for customer lifetime duration
- Scores on 1-4 scale (higher = more frequent)

### 4. Monetary Calculation
- Calculates average monthly revenue per customer
- Normalizes by active customer period
- Scores on 1-4 scale (higher = more valuable)

### 5. RFM Segmentation
- Combines R, F, M scores into three-digit codes (e.g., "444", "111")
- Groups customers by RFM segments
- Provides summary statistics

## Usage

1. **Setup Database**: Ensure your database contains the required tables with proper schema
2. **Run Analysis**: Execute the SQL script in sequence
3. **Review Results**: Check the `RFM_result` table for customer segment distribution

```sql
-- View final results
SELECT * FROM RFM_result ORDER BY number_customer DESC;
```

## RFM Score Interpretation

| Score | Recency | Frequency | Monetary |
|-------|---------|-----------|----------|
| 4 | Very Recent | Very Frequent | High Value |
| 3 | Recent | Frequent | Good Value |
| 2 | Moderate | Moderate | Average Value |
| 1 | Long Ago | Infrequent | Low Value |

## Example Segments

- **444**: Champions - Best customers (recent, frequent, high-value)
- **411**: New Customers - Recent buyers with potential
- **144**: Big Spenders - High-value but infrequent customers
- **111**: Lost Customers - Require re-engagement efforts

## Requirements

- MySQL 5.7+ or compatible SQL database
- Tables: `customer_registered`, `customer_transaction`
- Appropriate read/write permissions for creating views and temporary tables

## Configuration

Update the reference date in the analysis by changing `'2022-09-01'` to your desired analysis cutoff date throughout the script.

## Output

The final `RFM_result` table contains:
- `number_customer`: Count of customers in each segment
- `RFM`: Three-digit RFM code for the segment

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For questions or issues, please open a GitHub issue or contact the maintainer.
