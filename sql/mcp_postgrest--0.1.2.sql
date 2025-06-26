-- mcp_postgrest--0.1.2.sql

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

-- Global config
DO $$
BEGIN
  PERFORM set_config('mcp_postgrest.crud_autogen_enabled', 'on', false);
EXCEPTION WHEN OTHERS THEN
  NULL;
END$$;

-- Tool dispatcher
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

-- CRUD autogen
CREATE OR REPLACE FUNCTION create_crud_tools_for_table(tablename TEXT)
RETURNS VOID AS $$
DECLARE
  table_exists BOOLEAN;
  tool_prefix TEXT := 'tool_';
BEGIN
  IF current_setting('mcp_postgrest.crud_autogen_enabled', true)::boolean IS NOT TRUE THEN
    RAISE NOTICE 'Global autogen is disabled';
    RETURN;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = tablename
  ) INTO table_exists;

  IF NOT table_exists THEN
    RAISE EXCEPTION 'Table "%" does not exist', tablename;
  END IF;

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
  $f$, tool_prefix, tablename, tablename, tablename, tablename);

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

-- Auto hook on CREATE TABLE
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

DROP EVENT TRIGGER IF EXISTS mcp_auto_crud;
CREATE EVENT TRIGGER mcp_auto_crud
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE')
  EXECUTE FUNCTION mcp_on_create_table();

-- AI Codegen Tool
CREATE OR REPLACE FUNCTION generate_ai_tool(
  provider TEXT,
  api_key TEXT,
  tool_name TEXT,
  description TEXT,
  table_names TEXT[]
) RETURNS TEXT AS $$
DECLARE
  schema_description TEXT := '';
  table_def TEXT;
  i INT;
  curl_command TEXT;
BEGIN
  FOR i IN 1..array_length(table_names, 1) LOOP
    SELECT string_agg(column_name || ' ' || data_type, ', ') INTO table_def
    FROM information_schema.columns
    WHERE table_name = table_names[i];
    schema_description := schema_description || format('Table %s: %s\n', table_names[i], table_def);
  END LOOP;

  curl_command := format($$
    curl -s -X POST %s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer %s" \
    -d '{
      "model": "claude-3-opus-20240229",
      "stream": false,
      "max_tokens": 1024,
      "messages": [{
        "role": "user",
        "content": "Generate a PostgreSQL function that defines a tool called %s. Description: %s. Use these tables: %s"
      }]
    }'
  $$,
    CASE
      WHEN provider = 'anthropic' THEN 'https://api.anthropic.com/v1/messages'
      WHEN provider = 'openai' THEN 'https://api.openai.com/v1/chat/completions'
      ELSE 'invalid'
    END,
    api_key,
    tool_name, description, schema_description
  );

  RAISE NOTICE 'Execute manually:\n%s', curl_command;
  RETURN 'AI generation request prepared. Paste and run the curl command above.';
END;
$$ LANGUAGE plpgsql;
