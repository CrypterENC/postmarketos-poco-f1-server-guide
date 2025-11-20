#!/bin/bash

echo "Bot Monitoring Management Script"
echo "1. Enable bot monitoring (cAdvisor)"
echo "2. Undo bot monitoring"
echo "Choose an option (1 or 2):"
read -r choice

case $choice in
    1)
        echo "Enabling bot monitoring..."

        # Enable community repository if not already
        doas sed -i 's/#http.*\/community/http:\/\/dl-cdn.alpinelinux.org\/alpine\/latest-stable\/community/g' /etc/apk/repositories
        doas apk update

        # Install Docker if not already installed
        if ! command -v docker &> /dev/null; then
            doas apk add docker
            doas systemctl start docker
            doas systemctl enable docker
        fi

        # Run cAdvisor for container monitoring
        docker pull zcube/cadvisor:latest
        docker rm cadvisor || true
        docker run -d --name=cadvisor -p 8080:8080 --volume=/:/rootfs:ro --volume=/var/run:/var/run:ro --volume=/sys:/sys:ro --volume=/var/lib/docker/:/var/lib/docker:ro --volume=/dev/disk/:/dev/disk:ro --privileged --detach zcube/cadvisor:latest

        # Update Prometheus config to scrape cAdvisor
        if ! grep -q "job_name: 'cadvisor'" /etc/prometheus/prometheus.yml; then
            doas tee -a /etc/prometheus/prometheus.yml > /dev/null <<EOF

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
EOF
        fi

        doas systemctl restart prometheus

        echo "Bot monitoring enabled. cAdvisor is running and Prometheus is scraping container metrics."
        ;;
    2)
        echo "Undoing bot monitoring..."

        # Stop and remove cAdvisor container
        docker stop cadvisor || true
        docker rm cadvisor || true

        # Remove cAdvisor job from Prometheus config
        doas sed -i '/- job_name: '\''cadvisor'\''/,+4d' /etc/prometheus/prometheus.yml

        # Restart Prometheus to apply config changes
        doas systemctl restart prometheus || true

        echo "Bot monitoring has been undone."
        ;;
    *)
        echo "Invalid option. Please choose 1 or 2."
        exit 1
        ;;
esac
