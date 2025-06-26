-- MCP PostgREST Extension SQL
CREATE TABLE IF NOT EXISTS mcp_tools (
  id              SERIAL PRIMARY KEY,
  name            TEXT UNIQUE NOT NULL,
  description     TEXT,
  function_name   TEXT NOT NULL,
  input_schema    JSONB,
  output_schema   JSONB,
  config          JSONB DEFAULT '{}',
  allowed_roles   TEXT[],
  is_enabled      BOOLEAN DEFAULT TRUE
);

CREATE OR REPLACE FUNCTION call_tool(tool_name TEXT, args JSONB)
RETURNS JSONB AS $$
DECLARE
  tool mcp_tools%ROWTYPE;
  result JSONB;
BEGIN
  SELECT * INTO tool FROM mcp_tools
  WHERE name = tool_name AND is_enabled;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tool not found or disabled';
  END IF;

  IF tool.allowed_roles IS NOT NULL AND NOT (
    current_setting('request.jwt.claims.role', true) = ANY(tool.allowed_roles)
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  EXECUTE format('SELECT %I($1)', tool.function_name) INTO result USING args;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
