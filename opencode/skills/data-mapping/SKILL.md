---
name: data-mapping
description: Map Shopify data warehouse tables to strongly-typed code. Uses data-portal-mcp to discover tables, retrieve schemas, construct explicit SQL queries (no SELECT *), and generate type-safe interfaces in the project's language (TypeScript, Go, Ruby, etc.).
---

# Skill: Data Mapping

Map Shopify's data warehouse tables to strongly-typed code with explicit column selection and generated type definitions.

## Description

This skill provides a systematic workflow for:
1. Discovering relevant tables in Shopify's data platform
2. Understanding table schemas and column types
3. Constructing explicit SQL queries (never `SELECT *`)
4. Generating type-safe interfaces/structs in the project's programming language
5. Mapping query results to typed data structures

The goal is **type safety end-to-end**: from BigQuery schema to application code.

## Triggers

- "Map this table to types"
- "Create types for [table name]"
- "Query [data domain] with typed results"
- "Generate interface for BigQuery table"
- "Type-safe data access"
- "What tables have [X] data?"
- "Schema for [table]"

## Prerequisites

- `data-portal-mcp` server must be running and accessible
- For type generation: identify the project's primary language (TypeScript, Go, Ruby, Python, etc.)

## Workflow Steps

### 1. Understand the Data Platform

**Always start here** - call `list_data_platform_docs` to understand:
- Available data domains
- Naming conventions
- Medallion model (bronze/silver/gold)
- Which datasets are relevant to the request

```
Tool: data-portal-mcp_list_data_platform_docs
```

### 2. Search for Relevant Tables

Use `search_data_platform` with domain-scoped queries:

```
Tool: data-portal-mcp_search_data_platform
- dataplex_query: "(orders OR transactions) AND parent=bigquery:shopify-dw.finance"
- natural_language_query: "Tables containing order transaction data for revenue analysis"
```

**Search Best Practices:**
- Filter by domain: `AND parent=bigquery:shopify-dw.${dataset_id}`
- Use OR for synonyms: `(sales OR revenue OR orders)`
- Cast a wide net, then narrow down
- Present top 3 results to user with Data Portal links

### 3. Get Table Schema

Once a table is selected, retrieve full metadata:

```
Tool: data-portal-mcp_get_entry_metadata
- fully_qualified_name: "bigquery:shopify-dw.finance.gross_merchandise_volume"
```

**Extract from metadata:**
- All column names and their BigQuery types
- Partition columns (required for WHERE clauses)
- Column descriptions/documentation
- Primary keys and relationships

### 4. Construct Explicit SQL Query

**CRITICAL: Never use `SELECT *`**

Build queries with explicit column selection:

```sql
-- GOOD: Explicit columns
SELECT
  shop_id,
  order_id,
  created_at,
  total_amount_usd,
  currency_code
FROM `shopify-dw.finance.orders`
WHERE created_at >= '2024-01-01'
  AND shop_id = 12345

-- BAD: Never do this
SELECT * FROM `shopify-dw.finance.orders`
```

**Query Construction Rules:**
1. List every column explicitly
2. Include partition column in WHERE clause (required)
3. Use appropriate filters to limit data
4. Alias columns if needed for cleaner type names
5. Document the purpose of each selected column

### 5. Generate Type Definitions

Map BigQuery types to the project's language:

| BigQuery Type | TypeScript | Go | Ruby | Python |
|---------------|------------|-----|------|--------|
| STRING | `string` | `string` | `String` | `str` |
| INT64 | `number` | `int64` | `Integer` | `int` |
| FLOAT64 | `number` | `float64` | `Float` | `float` |
| NUMERIC | `number` | `decimal.Decimal` | `BigDecimal` | `Decimal` |
| BOOL | `boolean` | `bool` | `TrueClass/FalseClass` | `bool` |
| DATE | `string` | `time.Time` | `Date` | `date` |
| DATETIME | `string` | `time.Time` | `DateTime` | `datetime` |
| TIMESTAMP | `string` | `time.Time` | `Time` | `datetime` |
| BYTES | `Uint8Array` | `[]byte` | `String` | `bytes` |
| ARRAY<T> | `T[]` | `[]T` | `Array` | `list[T]` |
| STRUCT | `interface` | `struct` | `Struct/Hash` | `dataclass` |
| JSON | `unknown` | `json.RawMessage` | `Hash` | `dict` |

**Nullability:** BigQuery columns are nullable by default unless marked REQUIRED. Generate optional types accordingly.

### 6. Execute and Validate

Run the query to validate:

```
Tool: data-portal-mcp_query_bigquery
- query: "SELECT shop_id, order_id, ... FROM ..."
```

Review the results preview to confirm:
- Column types match expectations
- Data format is as expected
- No unexpected nulls in required fields

### 7. Generate Final Type Definition

**TypeScript Example:**
```typescript
/** 
 * Order data from shopify-dw.finance.orders
 * Query: SELECT shop_id, order_id, created_at, total_amount_usd, currency_code
 */
interface Order {
  /** Unique identifier for the shop */
  shop_id: number;
  /** Unique identifier for the order */
  order_id: number;
  /** When the order was created (ISO 8601) */
  created_at: string;
  /** Total order amount in USD (nullable for non-USD orders) */
  total_amount_usd: number | null;
  /** ISO 4217 currency code */
  currency_code: string;
}
```

**Go Example:**
```go
// Order represents data from shopify-dw.finance.orders
type Order struct {
    ShopID         int64    `json:"shop_id" bigquery:"shop_id"`
    OrderID        int64    `json:"order_id" bigquery:"order_id"`
    CreatedAt      string   `json:"created_at" bigquery:"created_at"`
    TotalAmountUSD *float64 `json:"total_amount_usd" bigquery:"total_amount_usd"`
    CurrencyCode   string   `json:"currency_code" bigquery:"currency_code"`
}
```

## Key Commands Reference

| Step | Tool | Purpose |
|------|------|---------|
| Context | `list_data_platform_docs` | Understand available data domains |
| Search | `search_data_platform` | Find relevant tables |
| Schema | `get_entry_metadata` | Get column names and types |
| Query | `query_bigquery` | Execute and validate SQL |
| Analyze | `analyze_query_results` | Inspect result data |

## Best Practices

### Query Design
- **Explicit columns only** - Never `SELECT *`
- **Document column purpose** - Add comments explaining why each column is selected
- **Filter aggressively** - Use WHERE clauses to limit data volume
- **Partition awareness** - Always filter on partition columns

### Type Safety
- **Match nullability** - Use optional types for nullable columns
- **Preserve precision** - Use appropriate numeric types (don't lose precision)
- **Document source** - Include table FQN and query in type comments
- **Version awareness** - Note if schema might change

### Naming Conventions
- **Interface names** - PascalCase, singular (e.g., `Order` not `Orders`)
- **Property names** - Match column names or use idiomatic casing for language
- **Include tags** - Add JSON/BigQuery struct tags where applicable

## Example Workflow

**User:** "I need to query shop revenue data and map it to TypeScript types"

**Agent:**
1. "Let me first understand the data platform structure."
   - Calls `list_data_platform_docs`

2. "I'll search for revenue-related tables in the finance domain."
   - Calls `search_data_platform` with `(revenue OR sales OR gmv) AND parent=bigquery:shopify-dw.finance`

3. "Found these tables. The `gross_merchandise_volume` table looks most relevant. Let me get its schema."
   - Calls `get_entry_metadata` for the selected table

4. "Based on the schema, here's an explicit query for the columns you'll need:"
   ```sql
   SELECT
     shop_id,
     reporting_date,
     gmv_usd,
     order_count,
     currency_code
   FROM `shopify-dw.finance.gross_merchandise_volume`
   WHERE reporting_date >= '2024-01-01'
   ```

5. "Let me validate this query."
   - Calls `query_bigquery`

6. "Query successful. Here's your TypeScript interface:"
   ```typescript
   interface ShopRevenue {
     shop_id: number;
     reporting_date: string;
     gmv_usd: number;
     order_count: number;
     currency_code: string;
   }
   ```

## Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| `SELECT *` | Explicitly list every column |
| Assume column types | Check schema with `get_entry_metadata` |
| Skip partition filters | Always include partition column in WHERE |
| Use `any` or untyped | Generate proper types from schema |
| Hardcode table names | Search and validate table exists first |
| Ignore nullability | Mark nullable columns as optional |
