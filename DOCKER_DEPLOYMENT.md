# NextGIS Web Docker Deployment

Production-ready Docker deployment for NextGIS Web GIS server.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum (8GB recommended)
- 10GB disk space minimum

## Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/madizm/nextgisweb.git
cd nextgisweb

# Copy environment template
cp .env.example .env

# Edit environment variables (IMPORTANT: change secrets!)
nano .env
```

### 2. Start Services

```bash
# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f nextgisweb
```

### 3. Access Application

Open your browser and navigate to:
- **Application**: http://localhost:8080
- **Default admin**: Will be created on first run (check logs for credentials)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_PASSWORD` | `nextgisweb_secret_password` | PostgreSQL password |
| `NGW_SECRET` | `your_secret_key_change_in_production` | Application secret key |
| `NGW_LOG_LEVEL` | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR) |
| `APP_PORT` | `8080` | External port for the application |

### Volumes

- `postgres_data`: PostgreSQL database files
- `nextgisweb_data`: Application data, cache, and logs

### Custom Configuration

Place custom configuration in `docker/config/config.local.cfg`:

```ini
[nextgisweb]
secret = your_production_secret
log.level = WARNING
```

## Production Deployment

### With Nginx Reverse Proxy

1. Uncomment the nginx service in `docker-compose.yml`
2. Configure your domain in `docker/nginx/nginx.conf`
3. Add SSL certificates to `docker/nginx/ssl/`
4. Update ports in docker-compose.yml (80/443)

### Security Checklist

- [ ] Change `DB_PASSWORD` to a strong password
- [ ] Change `NGW_SECRET` to a random secret (use `openssl rand -hex 32`)
- [ ] Enable HTTPS with valid SSL certificates
- [ ] Configure firewall rules
- [ ] Set up regular backups
- [ ] Monitor logs and set up alerts

## Management Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f nextgisweb
docker compose logs -f db
```

### Restart Services

```bash
# Restart application
docker compose restart nextgisweb

# Restart all
docker compose restart
```

### Database Backup

```bash
# Backup database
docker compose exec db pg_dump -U nextgisweb nextgisweb > backup.sql

# Restore database
docker compose exec -T db psql -U nextgisweb nextgisweb < backup.sql
```

### Update Application

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker compose up -d --build
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data!)
docker compose down -v
```

## Troubleshooting

### Application won't start

```bash
# Check logs
docker compose logs nextgisweb

# Verify database is healthy
docker compose ps
docker compose logs db
```

### Database connection errors

```bash
# Test database connection
docker compose exec db psql -U nextgisweb -d nextgisweb -c "SELECT 1"
```

### Permission issues

```bash
# Fix volume permissions
docker compose down
sudo chown -R 1000:1000 /var/nextgisweb  # if using host volumes
docker compose up -d
```

## Architecture

```
┌─────────────────┐
│     Nginx       │ (optional, port 80/443)
│   (reverse      │
│    proxy)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  NextGIS Web    │ (port 8080)
│   Application   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PostgreSQL     │
│  + PostGIS      │ (port 5432, internal)
└─────────────────┘
```

## Support

- Documentation: https://docs.nextgis.com/docs_ngweb/
- Community: https://community.nextgis.com
- Issues: https://github.com/nextgis/nextgisweb/issues

## License

GNU General Public License v3.0
