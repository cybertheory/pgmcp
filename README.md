# MCP-PostgREST Extension

## Overview
PostgreSQL extension to define AI tools compatible with Anthropic's Model Context Protocol (MCP). Fully customizable, schema-agnostic, secure, and integrated with PostgREST.

## Installation
1. Install PostgreSQL and PostgREST
2. Run `sql/mcp_postgrest--0.1.0.sql` inside your DB
3. Enable the extension:
```sql
CREATE EXTENSION mcp_postgrest;
```
4. Start PostgREST:
```bash
./bootstrap_mcp.sh
```

## Usage
Define tools in `mcp_tools`, then call them via PostgREST:
```bash
POST /rpc/call_tool
{
  "tool_name": "tool_add",
  "args": {"a": 2, "b": 3}
}
```

## License
MIT
