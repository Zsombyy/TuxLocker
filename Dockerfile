FROM nginx:alpine

# Set maintainer
LABEL maintainer="your-email@example.com"

# Install universal tools (works on Alpine, Debian, CentOS, etc.)
RUN if [ -f /etc/alpine-release ]; then \
        apk add --no-cache wget curl; \
    elif [ -f /etc/debian_version ]; then \
        apt-get update && apt-get install -y wget curl && apt-get clean && rm -rf /var/lib/apt/lists/*; \
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then \
        yum install -y wget curl && yum clean all; \
    elif command -v dnf > /dev/null; then \
        dnf install -y wget curl && dnf clean all; \
    elif command -v zypper > /dev/null; then \
        zypper install -y wget curl && zypper clean; \
    elif command -v pacman > /dev/null; then \
        pacman -Sy --noconfirm wget curl && pacman -Scc --noconfirm; \
    else \
        echo "Unsupported package manager" && exit 1; \
    fi

# Copy application files
COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

# Create log directory and set permissions (universal approach)
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx 2>/dev/null || chown -R www-data:www-data /var/log/nginx 2>/dev/null || true && \
    chown -R nginx:nginx /var/cache/nginx 2>/dev/null || chown -R www-data:www-data /var/cache/nginx 2>/dev/null || true && \
    chown -R nginx:nginx /usr/share/nginx/html 2>/dev/null || chown -R www-data:www-data /usr/share/nginx/html 2>/dev/null || true

# Set proper permissions (universal)
RUN chmod 644 /usr/share/nginx/html/index.html && \
    chmod 644 /etc/nginx/nginx.conf

# Test nginx configuration
RUN nginx -t

# Expose port
EXPOSE 80

# Universal health check (tries multiple methods)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health 2>/dev/null || \
        curl -f http://localhost/health >/dev/null 2>&1 || \
        nc -z localhost 80 || \
        exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
