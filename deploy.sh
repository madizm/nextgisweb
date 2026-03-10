#!/bin/bash
# NextGIS Web Docker Deployment Script
# Usage: ./deploy.sh [build|up|down|restart|logs]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from .env if exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

case "${1:-up}" in
    build)
        echo "🔨 Building NextGIS Web image..."
        docker-compose build --progress=plain
        ;;
    up)
        echo "🚀 Starting NextGIS Web deployment..."
        docker-compose up -d
        echo "✅ Deployment complete!"
        echo "   - NextGIS Web: http://localhost:${APP_PORT:-8080}"
        echo "   - Database: PostgreSQL/PostGIS 15-3.3"
        ;;
    down)
        echo "⏹️  Stopping NextGIS Web deployment..."
        docker-compose down
        ;;
    restart)
        echo "🔄 Restarting NextGIS Web..."
        docker-compose restart
        ;;
    logs)
        docker-compose logs -f ${2:-}
        ;;
    status)
        docker-compose ps
        ;;
    init-db)
        echo "🗄️  Initializing database..."
        docker-compose exec nextgisweb nextgisweb initialize_db
        ;;
    *)
        echo "Usage: $0 {build|up|down|restart|logs|status|init-db}"
        exit 1
        ;;
esac
