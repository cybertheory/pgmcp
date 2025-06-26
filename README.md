# 🚀 MCP PostgREST Extension

The `mcp_postgrest` PostgreSQL extension turns your database into an AI-ready tool server by exposing **structured tool definitions**, **auto-generated CRUD tools**, and **secure access control** — all compatible with [Anthropic’s Model Context Protocol (MCP)](https://docs.anthropic.com/claude/docs/tool-use).

> ✅ Works out-of-the-box with PostgREST for building RESTful tool endpoints

---

## 🔧 Features

### 🧠 MCP-Compatible Tool Interface

* Define tools directly in your database via the `mcp_tools` table.
* Each tool links to a `plpgsql` function, input/output schemas (JSON Schema), and optional role restrictions.
* Tools are callable via the unified dispatcher:

  ```sql
  SELECT call_tool('tool_name', '{"arg1": "value"}'::jsonb);
  ```

---

### ⚙️ Automatic CRUD Tool Generation

* On every `CREATE TABLE`, the extension can automatically generate:

  * A `tool_create_<table>` function
  * A corresponding entry in `mcp_tools`
* Keeps your tool registry updated as your schema evolves
* Behavior is fully configurable (see below)

---

### 🛡️ Access Control

* Use PostgreSQL **Row-Level Security (RLS)** on your data tables
* Limit tool usage to roles via the `allowed_roles` field in `mcp_tools`
* Optional column-based control for custom behavior

---

### 🪛 Define Your Own Tools

Define any business logic as a PostgreSQL function:

```sql
CREATE FUNCTION get_weather(params JSONB)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- pretend we're fetching weather
  result := jsonb_build_object('temp', 72, 'unit', 'F');
  RETURN result;
END;
$$ LANGUAGE plpgsql;
```

Register it as a tool:

```sql
INSERT INTO mcp_tools (name, description, function_name, input_schema, output_schema)
VALUES (
  'get_weather',
  'Returns current weather based on location',
  'get_weather',
  '{"type":"object","properties":{"location":{"type":"string"}},"required":["location"]}',
  '{"type":"object"}'
);
```

---

## ⚙️ Installation

### 1. Install Extension Files

Copy files to your PostgreSQL installation's extension folder:

```bash
cp mcp_postgrest.control /usr/share/postgresql/extension/
cp sql/mcp_postgrest--0.1.1.sql /usr/share/postgresql/extension/
```

> You can use `pg_config --sharedir` to find the right directory.

---

### 2. Enable the Extension

In your target database:

```sql
CREATE EXTENSION mcp_postgrest;
```

---

## 🔄 Configuration

### 🔁 Global Auto-CRUD Toggle

Enable/disable automatic CRUD tool generation:

```sql
-- Disable (session scope)
SET mcp_postgrest.crud_autogen_enabled = 'off';

-- Enable
SET mcp_postgrest.crud_autogen_enabled = 'on';
```

To make it permanent, add this to `postgresql.conf`:

```conf
mcp_postgrest.crud_autogen_enabled = 'off'
```

---

### ❌ Table-Level Opt-Out

To disable autogen for specific tables:

```sql
INSERT INTO mcp_crud_config (table_name, autogen_enabled)
VALUES ('sensitive_table', false);
```

---

## 📤 API Integration with PostgREST

If you use [PostgREST](https://postgrest.org/), all your tools (i.e. `call_tool`) are instantly accessible as HTTP endpoints via RPC:

```http
POST /rpc/call_tool
Content-Type: application/json

{
  "tool_name": "get_weather",
  "args": { "location": "San Francisco" }
}
```

> Combine with PostgREST role-based access to create secure tool routers!

---

## 📚 Tables

### `mcp_tools`

| Column          | Description                        |
| --------------- | ---------------------------------- |
| `name`          | Unique tool name                   |
| `description`   | Tool description                   |
| `function_name` | Name of function to invoke         |
| `input_schema`  | Input JSON schema                  |
| `output_schema` | Output JSON schema                 |
| `config`        | Optional tool-level config (JSONB) |
| `allowed_roles` | Allowed Postgres roles (TEXT\[])   |
| `is_enabled`    | Is the tool active?                |

---

### `mcp_crud_config`

| Column            | Description                            |
| ----------------- | -------------------------------------- |
| `table_name`      | Name of table                          |
| `autogen_enabled` | Boolean flag to enable/disable autogen |

---

## 🧪 Example

```sql
CREATE TABLE products(name TEXT, price INT);

-- This auto-generates:
-- - FUNCTION tool_create_products(JSONB)
-- - ENTRY in mcp_tools named "create_products"

-- To use:
SELECT call_tool('create_products', '{"name": "Shoes", "price": 80}');
```

---

## 🪪 License

MIT — use freely, modify, share, and fork.
