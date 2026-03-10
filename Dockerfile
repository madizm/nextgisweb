# NextGIS Web Dockerfile
# Multi-stage build for production deployment with frontend assets

FROM ubuntu:22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NGWROOT=/opt/nextgisweb

# Use Chinese mirrors for faster downloads in China
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    # Python
    python3.10 \
    python3.10-dev \
    python3-pip \
    # Node.js will be installed separately via NodeSource (need v20+)
    curl \
    ca-certificates \
    gnupg \
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

# Install Node.js 20.x via NodeSource (required for frontend build)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install yarn via npm (more reliable than apt)
RUN npm install -g yarn

# Get GDAL version for pygdal
RUN GDAL_VERSION=$(gdal-config --version) && \
    echo "GDAL_VERSION=$GDAL_VERSION" >> /root/.bashrc

WORKDIR /opt/nextgisweb

# Copy project files
COPY . .

# Install Python dependencies (using Tsinghua PyPI mirror for China)
RUN pip3 install --upgrade pip setuptools packaging -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    GDAL_VERSION=$(gdal-config --version) && \
    pip install "pygdal==${GDAL_VERSION}.*" 'numpy<2' -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install --no-build-isolation -e . -i https://pypi.tuna.tsinghua.edu.cn/simple

# Create data directories and set permissions
RUN mkdir -p /var/nextgisweb/{data,cache,log} && \
    mkdir -p dist && \
    chmod -R 755 /var/nextgisweb && \
    chown -R 1000:1000 /opt/nextgisweb

# Run as root for now (volume permission handling)
# TODO: Switch to non-root user with proper su-exec setup
# USER 1000:1000

# Build frontend assets
RUN nextgisweb jsrealm install --build

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')" || exit 1

# Default command
CMD ["python3", "-m", "waitress", "--host=0.0.0.0", "--port=8080", "nextgisweb:main"]
