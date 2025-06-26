# 🚀 MCP PostgREST Extension

The `mcp_postgrest` PostgreSQL extension transforms your database into an AI-powered tool interface compliant with [Anthropic’s Model Context Protocol (MCP)](https://docs.anthropic.com/claude/docs/tool-use).

> ✅ Secure, extensible, PostgREST-compatible, and now supports **AI-assisted function generation** using OpenAI or Anthropic models.

---

## 🔧 Features

### 🧠 MCP-Compatible Tool Interface

- Define tools directly via the `mcp_tools` table
- Each tool maps to a PostgreSQL function, with JSON Schema for inputs/outputs
- Callable with:
  ```sql
  SELECT call_tool('tool_name', '{"arg1": "value"}'::jsonb);
  ```

---

### ⚙️ Automatic CRUD Tool Generation

- On `CREATE TABLE`, generates:
  - A `tool_create_<table>` function
  - A corresponding entry in `mcp_tools`
- Globally toggleable using:
  ```sql
  SET mcp_postgrest.crud_autogen_enabled = 'on'; -- or 'off'
  ```

---

### 🤖 AI-Based Tool Generation (NEW)

Use OpenAI or Anthropic to **generate PostgreSQL tool functions** using your existing schema!

```sql
SELECT generate_ai_tool(
  provider := 'openai',         -- or 'anthropic'
  api_key := '<your-api-key>',
  tool_name := 'summarize_customers',
  description := 'Summarize customer behavior for marketing',
  table_names := ARRAY['customers', 'orders']
);
```

This returns:
- ✅ A ready-to-run `curl` command
- 🧠 Prompt includes inferred schema details
- 🎯 Output (when pasted into shell and run) will generate SQL you can paste back into the DB

---

### 🛡️ Security & Access Control

- PostgreSQL RLS-compatible
- Tools can be role-restricted via `allowed_roles` in `mcp_tools`
- Tool behavior is customizable per-function

---

## 📦 Installation

### 1. Copy Extension Files

```bash
cp mcp_postgrest.control /usr/share/postgresql/extension/
cp sql/mcp_postgrest--0.1.1.sql /usr/share/postgresql/extension/
```

> Check your location with `pg_config --sharedir`

---

### 2. Create the Extension

```sql
CREATE EXTENSION mcp_postgrest;
```

---

## 🔄 Configuration

### Global Auto-CRUD Toggle

```sql
SET mcp_postgrest.crud_autogen_enabled = 'on';  -- or 'off'
```

In `postgresql.conf` for permanent config:

```conf
mcp_postgrest.crud_autogen_enabled = 'on'
```

---

## 📚 Tables & Functions

### `mcp_tools`

| Column         | Description                                    |
|----------------|------------------------------------------------|
| `name`         | Unique tool name                               |
| `description`  | Tool purpose                                   |
| `function_name`| Underlying PostgreSQL function                 |
| `input_schema` | JSON Schema for input validation               |
| `output_schema`| JSON Schema for output validation              |
| `allowed_roles`| Allowed PostgreSQL roles                       |
| `is_enabled`   | Boolean toggle for tool availability           |
| `config`       | Optional JSONB config                          |

---

### `call_tool(tool_name, args JSONB)` → JSONB

Dispatches a request to the corresponding function with proper access control and input.

---

### `generate_ai_tool(provider, api_key, tool_name, description, table_names[])`

Returns a `curl` command using the selected LLM provider (`openai` or `anthropic`) with schema-aware context to generate SQL functions.

---

## 🧪 Example

```sql
CREATE TABLE products(name TEXT, price INT);

-- Generates:
-- - tool_create_products(JSONB)
-- - mcp_tools entry: create_products

SELECT call_tool('create_products', '{"name": "Shoe", "price": 50}');
```

---

## 🌐 PostgREST Integration

PostgREST automatically exposes all `call_tool` RPCs:

```http
POST /rpc/call_tool
Content-Type: application/json

{
  "tool_name": "get_weather",
  "args": { "location": "New York" }
}
```

---

## 🪪 License

MIT — Open Source. Build responsibly.

---

## 📬 Coming Soon

- ✅ Streamed response support for `HTTPStreamable`
- 🧠 Tool chaining + tool logs
- 🔄 AI loop completion from within the DB
