#!/bin/bash

echo "Main Monitoring Stack Management Script"
echo "1. Deploy monitoring stack (Prometheus, Node Exporter, Grafana)"
echo "2. Undo monitoring stack"
echo "Choose an option (1 or 2):"
read -r choice

case $choice in
    1)
        echo "Deploying monitoring stack..."

        # Update system and enable community repository
        doas apk update
        doas apk upgrade
        doas sed -i 's/#http.*\/community/http:\/\/dl-cdn.alpinelinux.org\/alpine\/latest-stable\/community/g' /etc/apk/repositories
        doas apk update

        # Install Node Exporter, Prometheus, Grafana
        doas apk add prometheus prometheus-node-exporter grafana

        # Create systemd service for Prometheus
        doas tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

        # Create systemd service for Node Exporter
        doas tee /etc/systemd/system/node-exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node-exporter
Group=node-exporter
ExecStart=/usr/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

        # Create systemd service for Grafana
        doas tee /etc/systemd/system/grafana.service > /dev/null <<EOF
[Unit]
Description=Grafana
After=network.target

[Service]
Type=simple
User=grafana
Group=grafana
ExecStart=/usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --homepath=/usr/share/grafana
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

        # Configure Prometheus to scrape Node Exporter
        doas tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

        # Ensure users exist
        doas addgroup -S prometheus 2>/dev/null || true
        doas adduser -S -D -H -h /var/empty -s /sbin/nologin -G prometheus -g prometheus prometheus 2>/dev/null || true
        doas addgroup -S node-exporter 2>/dev/null || true
        doas adduser -S -D -H -h /var/empty -s /sbin/nologin -G node-exporter -g node-exporter node-exporter 2>/dev/null || true
        doas addgroup -S grafana 2>/dev/null || true
        doas adduser -S -D -H -h /var/empty -s /sbin/nologin -G grafana -g grafana grafana 2>/dev/null || true

        # Create directories for Grafana
        doas mkdir -p /etc/grafana /var/lib/grafana /var/log/grafana
        doas mkdir -p /var/lib/prometheus

        # Create basic Grafana config
        doas tee /etc/grafana/grafana.ini > /dev/null <<EOF
[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = admin
admin_password = admin

[paths]
data = /var/lib/grafana
logs = /var/log/grafana
EOF

        # Set permissions
        doas chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
        doas chown -R grafana:grafana /etc/grafana /var/lib/grafana /var/log/grafana

        # Start and enable services with systemd
        doas systemctl daemon-reload
        doas systemctl start prometheus
        doas systemctl start node-exporter
        doas systemctl start grafana
        doas systemctl enable prometheus
        doas systemctl enable node-exporter
        doas systemctl enable grafana

        # Reload and restart Grafana to apply any config changes
        doas systemctl daemon-reload
        doas systemctl restart grafana
        doas systemctl status grafana

        echo "Monitoring setup complete. Access Grafana at http://your-server-ip:3000"
        ;;
    2)
        echo "Undoing monitoring stack..."

        # Stop and disable services
        doas systemctl stop prometheus
        doas systemctl stop node-exporter
        doas systemctl stop grafana
        doas systemctl disable prometheus
        doas systemctl disable node-exporter
        doas systemctl disable grafana

        # Remove systemd service files
        doas rm -f /etc/systemd/system/prometheus.service
        doas rm -f /etc/systemd/system/node-exporter.service
        doas rm -f /etc/systemd/system/grafana.service

        # Reload systemd
        doas systemctl daemon-reload

        # Remove packages
        doas apk del prometheus prometheus-node-exporter grafana

        # Remove users and groups
        doas deluser prometheus 2>/dev/null || true
        doas delgroup prometheus 2>/dev/null || true
        doas deluser node-exporter 2>/dev/null || true
        doas delgroup node-exporter 2>/dev/null || true
        doas deluser grafana 2>/dev/null || true
        doas delgroup grafana 2>/dev/null || true

        # Remove data directories (optional - comment out if you want to keep data)
        # doas rm -rf /etc/prometheus /var/lib/prometheus
        # doas rm -rf /etc/grafana /var/lib/grafana /var/log/grafana

        echo "Monitoring setup has been removed."
        ;;
    *)
        echo "Invalid option. Please choose 1 or 2."
        exit 1
        ;;
esac