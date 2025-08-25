#!/bin/bash
# Docker Volume Backup Script

BACKUP_DIR="/backup/docker"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# List all Docker volumes
echo "=== Docker Volumes ==="
docker volume ls

echo ""
echo "Creating backup of all Docker volumes..."

# Backup each volume
for volume in $(docker volume ls -q); do
    echo "Backing up volume: $volume"
    docker run --rm \
        -v "$volume":/source:ro \
        -v "$BACKUP_DIR":/backup \
        ubuntu \
        tar czf "/backup/${volume}_${DATE}.tar.gz" -C /source .
done

echo "Docker volume backup completed"
