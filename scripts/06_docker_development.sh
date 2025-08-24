#!/bin/bash

# Ubuntu 24.04.3 Docker & Development Setup
# Implements Docker CE with optimizations and development tools

set -e

echo "=== 6. Docker & Development Setup ==="

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed:"
    docker --version
else
    echo "Installing Docker CE..."
    
    # Install prerequisites
    sudo apt update
    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# Add user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Configure Docker daemon with optimizations
echo "Configuring Docker daemon..."
sudo mkdir -p /etc/docker

# Create Docker daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "features": {
    "buildkit": true
  },
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
EOF

# Enable cgroup v2 (should be default in Ubuntu 24.04)
echo "Checking cgroup version..."
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "✓ cgroup v2 is enabled"
else
    echo "⚠ cgroup v2 might not be fully enabled"
fi

# Enable and start Docker services
echo "Enabling Docker services..."
sudo systemctl enable docker
sudo systemctl enable containerd
sudo systemctl restart docker

# Install Docker Compose (standalone)
echo "Installing Docker Compose standalone..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create Docker Compose project directory structure
echo "Creating Docker project structure..."
mkdir -p /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/docker-projects

# Create example multi-container project
mkdir -p /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/docker-projects/web-stack

tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/docker-projects/web-stack/docker-compose.yml > /dev/null << 'EOF'
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - web_data:/var/www/html
    depends_on:
      - wordpress
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  wordpress:
    image: wordpress:latest
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - web_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  wireguard:
    image: linuxserver/wireguard
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - SERVERURL=auto
      - SERVERPORT=51820
      - PEERS=5
    volumes:
      - ./wireguard:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped

volumes:
  web_data:
  db_data:

networks:
  default:
    driver: bridge
EOF

# Create basic nginx configuration
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/docker-projects/web-stack/nginx.conf > /dev/null << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream wordpress {
        server wordpress:80;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://wordpress;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Create Docker management scripts
tee /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/docker_manage.sh > /dev/null << 'EOF'
#!/bin/bash
# Docker Management Script

case "$1" in
    "status")
        echo "=== Docker Status ==="
        echo "Docker version:"
        docker --version
        echo ""
        echo "Docker Compose version:"
        docker-compose --version
        echo ""
        echo "Running containers:"
        docker ps
        echo ""
        echo "Docker system info:"
        docker system df
        ;;
    "cleanup")
        echo "=== Docker Cleanup ==="
        echo "Removing stopped containers..."
        docker container prune -f
        echo "Removing unused images..."
        docker image prune -f
        echo "Removing unused volumes..."
        docker volume prune -f
        echo "Removing unused networks..."
        docker network prune -f
        echo "Cleanup complete"
        ;;
    "logs")
        if [ -z "$2" ]; then
            echo "Usage: $0 logs <container_name>"
            exit 1
        fi
        docker logs -f "$2"
        ;;
    "stats")
        docker stats
        ;;
    *)
        echo "Usage: $0 {status|cleanup|logs|stats}"
        echo "  status  - Show Docker status and running containers"
        echo "  cleanup - Clean up unused Docker resources"
        echo "  logs    - Show logs for a specific container"
        echo "  stats   - Show container resource usage"
        exit 1
        ;;
esac
EOF

chmod +x /media/michael-princ/E85AE8F65AE8C284/Data_science_projects/Ubuntu_24.04_fine_tuning/scripts/docker_manage.sh

# Test Docker installation
echo "=== Docker Status Check ==="
echo "Docker version:"
docker --version

echo ""
echo "Docker Compose version:"
docker-compose --version

echo ""
echo "Docker service status:"
sudo systemctl status docker --no-pager -l | head -10

echo ""
echo "Docker system info:"
docker system info | head -20

echo "=== Docker & Development Setup Complete ==="
echo "Note: You may need to log out and back in for docker group changes to take effect"
echo "Test Docker: docker run hello-world"
echo "Web stack example: cd docker-projects/web-stack && docker-compose up -d"
