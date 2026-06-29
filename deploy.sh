#!/bin/bash

PROJECT_NAME="product-catalog"

case "$1" in

  start)
    echo "🚀 Starting all services..."
    docker compose up -d --build
    echo "✅ All services started"
    ;;

  stop)
    echo "🛑 Stopping all services..."
    docker compose down
    echo "✅ All services stopped"
    ;;

  restart)
    echo "🔄 Restarting services..."
    docker compose down
    docker compose up -d --build
    echo "✅ Restart complete"
    ;;

  status)
    echo "📊 Service status:"
    docker compose ps
    echo ""
    echo "🩺 Health checks (if available):"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    ;;

  logs)
    docker compose logs -f
    ;;

  *)
    echo "Usage: ./deploy.sh {start|stop|restart|status|logs}"
    ;;
esac
