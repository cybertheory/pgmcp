-- MCP Tool Interface Extension with Auto-CRUD and GUC Config

-- Tool registry
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

-- Table-level config override
CREATE TABLE IF NOT EXISTS mcp_crud_config (
  table_name TEXT PRIMARY KEY,
  autogen_enabled BOOLEAN DEFAULT TRUE
);

-- Default global config (as GUC)
DO $$
BEGIN
  PERFORM set_config('mcp_postgrest.crud_autogen_enabled', 'on', false);
EXCEPTION WHEN OTHERS THEN
  -- Ignore if already set
  NULL;
END$$;

-- Main dispatcher function
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

-- Auto-CRUD generator
CREATE OR REPLACE FUNCTION create_crud_tools_for_table(tablename TEXT)
RETURNS VOID AS $$
DECLARE
  table_exists BOOLEAN;
  tool_prefix TEXT := 'tool_';
BEGIN
  -- Global toggle via GUC
  IF current_setting('mcp_postgrest.crud_autogen_enabled', true)::boolean IS NOT TRUE THEN
    RAISE NOTICE 'Global autogen is disabled';
    RETURN;
  END IF;

  -- Opt-out for specific tables
  IF EXISTS (
    SELECT 1 FROM mcp_crud_config WHERE table_name = tablename AND autogen_enabled = FALSE
  ) THEN
    RAISE NOTICE 'Autogen disabled for table %', tablename;
    RETURN;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = tablename
  ) INTO table_exists;

  IF NOT table_exists THEN
    RAISE EXCEPTION 'Table "%" does not exist', tablename;
  END IF;

  -- CREATE tool
  EXECUTE format($f$
    CREATE OR REPLACE FUNCTION %I_create_%I(params JSONB)
    RETURNS JSONB AS $$
    DECLARE inserted JSONB;
    BEGIN
      EXECUTE format('INSERT INTO %I(name, value) VALUES ($1, $2) RETURNING to_jsonb(%I)', '%I', '%I')
      USING params->>'name', (params->>'value')::INT INTO inserted;
      RETURN inserted;
    END;
    $$ LANGUAGE plpgsql;
  $f$, tool_prefix, tablename, tablename, tablename);

  -- Tool metadata insert
  INSERT INTO mcp_tools (name, description, function_name, input_schema, output_schema)
  VALUES (
    format('create_%s', tablename),
    format('Create a %s row', tablename),
    format('%s_create_%s', tool_prefix, tablename),
    '{"type":"object","properties":{"name":{"type":"string"},"value":{"type":"integer"}},"required":["name","value"]}',
    '{"type":"object"}'
  )
  ON CONFLICT (name) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Event trigger wrapper
CREATE OR REPLACE FUNCTION mcp_on_create_table()
RETURNS event_trigger AS $$
DECLARE
  obj RECORD;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
    IF obj.object_type = 'table' THEN
      PERFORM create_crud_tools_for_table(obj.object_identity::TEXT);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Register trigger
DROP EVENT TRIGGER IF EXISTS mcp_auto_crud;
CREATE EVENT TRIGGER mcp_auto_crud
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE')
  EXECUTE FUNCTION mcp_on_create_table();
