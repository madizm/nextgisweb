# NextGIS Web Dockerfile
# Multi-stage build for production deployment

FROM ubuntu:22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NGWROOT=/opt/nextgisweb

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Python
    python3.10 \
    python3.10-dev \
    python3-pip \
    # GDAL and geospatial libraries
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    # PostgreSQL client
    postgresql-client \
    # System utilities
    build-essential \
    libpcre3 \
    libpcre3-dev \
    gettext \
    libmagic1 \
    libxml2-dev \
    libxslt1-dev \
    libffi-dev \
    libssl-dev \
    # Cleanup
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Get GDAL version for pygdal
RUN GDAL_VERSION=$(gdal-config --version) && \
    echo "GDAL_VERSION=$GDAL_VERSION" >> /root/.bashrc

WORKDIR /opt/nextgisweb

# Copy project files
COPY . .

# Install Python dependencies
RUN pip3 install --upgrade pip setuptools packaging && \
    GDAL_VERSION=$(gdal-config --version) && \
    pip install "pygdal==${GDAL_VERSION}.*" numpy<2 && \
    pip install --no-build-isolation -e .

# Create data directories
RUN mkdir -p /var/nextgisweb/{data,cache,log} && \
    chmod -R 755 /var/nextgisweb

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')" || exit 1

# Default command
CMD ["python3", "-m", "waitress", "--host=0.0.0.0", "--port=8080", "nextgisweb:main"]
