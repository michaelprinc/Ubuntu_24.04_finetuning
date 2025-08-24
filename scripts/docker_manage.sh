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
