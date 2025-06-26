#!/bin/bash
if ! command -v postgrest &> /dev/null; then
  echo "PostgREST not found. Installing..."
  curl -L https://github.com/PostgREST/postgrest/releases/latest/download/postgrest-linux-static-x64.tar.xz | tar -xJ
  sudo mv postgrest /usr/local/bin/
fi

cat <<EOF > postgrest.conf
db-uri = "postgres://$PGUSER:$PGPASSWORD@localhost:$PGPORT/$PGDATABASE"
db-schema = "public"
db-anon-role = "anon"
jwt-secret = "your-secret-key"
EOF

echo "Starting PostgREST on port 3000..."
nohup postgrest postgrest.conf > postgrest.log 2>&1 &
echo "PostgREST is now running. Access it at http://localhost:3000"
