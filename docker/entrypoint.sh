#!/bin/sh
set -e

# Create directories if they don't exist (running as root)
mkdir -p /var/nextgisweb/{data,cache,log}

# Initialize database only if not already initialized
# Check if nextgisweb tables exist (not just PostGIS tables)
if ! python3 -c "
import psycopg2
conn = psycopg2.connect('${NGW_DATABASE_URL:-postgresql://nextgisweb:nextgisweb_secret_password@db:5432/nextgisweb}')
cur = conn.cursor()
cur.execute(\"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'setting%'\")
count = cur.fetchone()[0]
cur.close()
conn.close()
exit(0 if count > 0 else 1)
" 2>/dev/null; then
    echo "Database not initialized, running initialize_db..."
    nextgisweb initialize_db
else
    echo "Database already initialized, skipping initialization"
fi

# Execute the main command
exec "$@"
