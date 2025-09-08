#!/bin/bash

echo "Starting CMS Template Development Environment..."

# Build and start the development environment
docker-compose -f docker-compose.dev.yml up --build

# Alternative commands:
# docker-compose -f docker-compose.dev.yml up --build -d  # Run in background
# docker-compose -f docker-compose.dev.yml down           # Stop containers
# docker-compose -f docker-compose.dev.yml logs -f        # View logs