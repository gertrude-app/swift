---
name: database
description:
  Query and analyze the Gertrude PostgreSQL database. Use when answering questions about
  database schema, writing SQL queries, analyzing data, or debugging database-related
  issues. Has read-only access via the 'readonly' user.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Database Query Skill

You have read-only access to the Gertrude PostgreSQL database for querying and analysis.

## Connection Information

- **Database name**: `gertrude`
- **User**: `readonly`
- **Password**: None required
- **Connection command**: `psql -U readonly -d gertrude`

## Database Structure

The database uses multiple schemas to organize tables:

- **parent**: Parent accounts, children, computers, keychains, keys, notifications, etc.
- **child**: Computer users, blocked apps, iOS devices, tokens, screenshots
- **macapp**: Keystroke lines, releases, unlock requests
- **iosapp**: Block groups, rules, device configurations, suspend requests
- **macos**: App bundle IDs, categories, browsers, identified/unidentified apps
- **system**: Deleted entities, interesting events, security events, Stripe events
- **public**: Fluent migrations, jobs metadata
- **podcasts**: Podcast-related tables

## Common Commands

### Introspect Schema

```bash
# List all tables with their schemas
psql -U readonly -d gertrude -c "\dt"

# List all schemas with privileges
psql -U readonly -d gertrude -c "\dn+"

# Describe a specific table (show columns, types, constraints)
psql -U readonly -d gertrude -c "\d parent.parents"
psql -U readonly -d gertrude -c "\d+ parent.parents"  # with more details

# List all columns in a schema
psql -U readonly -d gertrude -c "\d parent.*"
```

### Query Data

```bash
# Run a simple query
psql -U readonly -d gertrude -c "SELECT * FROM parent.parents LIMIT 10;"

# Run a formatted query with better output
psql -U readonly -d gertrude -c "SELECT id, email, created_at FROM parent.parents ORDER BY created_at DESC LIMIT 5;"

# Count records
psql -U readonly -d gertrude -c "SELECT COUNT(*) FROM parent.parents;"

# Complex queries with joins (example)
psql -U readonly -d gertrude -c "
  SELECT p.email, COUNT(c.id) as num_children
  FROM parent.parents p
  LEFT JOIN parent.children c ON c.parent_id = p.id
  GROUP BY p.email
  LIMIT 10;
"
```

### Format Output

```bash
# Use expanded display for wide tables
psql -U readonly -d gertrude -c "\x" -c "SELECT * FROM parent.parents LIMIT 1;"

# Export to CSV
psql -U readonly -d gertrude -c "COPY (SELECT * FROM parent.parents LIMIT 10) TO STDOUT WITH CSV HEADER;"
```

## Workflow

1. **Understand the question**: Determine what data or schema information is needed
2. **Introspect first**: Use `\d` commands to understand table structure before writing
   queries
3. **Write queries**: Construct appropriate SELECT queries to answer the question
4. **Analyze results**: Interpret the query results and provide clear explanations
5. **Verify permissions**: If you attempt any write operation, you'll get a permission
   error (this is expected)

## Important Notes

- **Read-only access**: You cannot INSERT, UPDATE, DELETE, or modify the database in any
  way
- **Schema qualification**: Always use schema-qualified table names (e.g.,
  `parent.parents`, not just `parents`)
- **Query carefully**: Start with small LIMIT clauses to avoid overwhelming output
- **Explain results**: After running queries, provide clear explanations of what the data
  shows

## Examples

### Example 1: How many parents are in the system?

```bash
psql -U readonly -d gertrude -c "SELECT COUNT(*) as total_parents FROM parent.parents;"
```

### Example 2: What are the recent security events?

```bash
psql -U readonly -d gertrude -c "
  SELECT id, event_type, detail, created_at
  FROM system.security_events
  ORDER BY created_at DESC
  LIMIT 10;
"
```

### Example 3: What columns are in the computers table?

```bash
psql -U readonly -d gertrude -c "\d parent.computers"
```
