#!/bin/bash

# Battery check script for PostmarketOS on Xiaomi Poco F1
# This script checks battery status using sysfs and optionally upower

echo "=== Battery Information ==="
echo

# Check battery via sysfs
BAT_DIR=$(ls -d /sys/class/power_supply/*battery* 2>/dev/null | head -1)

if [ -n "$BAT_DIR" ]; then
    echo "Battery found at: $BAT_DIR"
    echo

    # Capacity
    if [ -f "$BAT_DIR/capacity" ]; then
        CAPACITY=$(cat "$BAT_DIR/capacity")
        echo "Battery Level: $CAPACITY%"
    fi

    # Status (Charging, Discharging, etc.)
    if [ -f "$BAT_DIR/status" ]; then
        STATUS=$(cat "$BAT_DIR/status")
        echo "Status: $STATUS"
    fi

    # Voltage
    if [ -f "$BAT_DIR/voltage_now" ]; then
        VOLTAGE=$(cat "$BAT_DIR/voltage_now")
        VOLTAGE_MV=$((VOLTAGE / 1000))
        echo "Voltage: $VOLTAGE_MV mV"
    fi

    # Current
    if [ -f "$BAT_DIR/current_now" ]; then
        CURRENT=$(cat "$BAT_DIR/current_now")
        CURRENT_MA=$((CURRENT / 1000))
        echo "Current: $CURRENT_MA mA"
    fi

    # Health
    if [ -f "$BAT_DIR/health" ]; then
        HEALTH=$(cat "$BAT_DIR/health")
        echo "Health: $HEALTH"
    fi

    # Temperature (in deci-degrees Celsius)
    if [ -f "$BAT_DIR/temp" ]; then
        TEMP=$(cat "$BAT_DIR/temp")
        TEMP_C=$((TEMP / 10))
        echo "Temperature: $TEMP_C°C"
    fi

    echo
else
    echo "No battery device found in /sys/class/power_supply/"
    echo "This may indicate battery monitoring is not available or the device is plugged in."
    echo
fi

# Check charger status
CHARGER_DIR=$(ls -d /sys/class/power_supply/*charger* 2>/dev/null | head -1)
if [ -n "$CHARGER_DIR" ]; then
    echo "=== Charger Information ==="
    echo "Charger found at: $CHARGER_DIR"
    echo

    if [ -f "$CHARGER_DIR/online" ]; then
        ONLINE=$(cat "$CHARGER_DIR/online")
        echo "Charger Online: $ONLINE"
    fi

    if [ -f "$CHARGER_DIR/status" ]; then
        CHG_STATUS=$(cat "$CHARGER_DIR/status")
        echo "Charger Status: $CHG_STATUS"
    fi

    if [ -f "$CHARGER_DIR/voltage_now" ]; then
        CHG_VOLTAGE=$(cat "$CHARGER_DIR/voltage_now")
        CHG_VOLTAGE_MV=$((CHG_VOLTAGE / 1000))
        echo "Charger Voltage: $CHG_VOLTAGE_MV mV"
    fi

    if [ -f "$CHARGER_DIR/current_max" ]; then
        CHG_CURRENT_MAX=$(cat "$CHARGER_DIR/current_max")
        CHG_CURRENT_MAX_MA=$((CHG_CURRENT_MAX / 1000))
        echo "Charger Max Current: $CHG_CURRENT_MAX_MA mA"
    fi

    echo
fi

# Check if upower is available for more detailed info
if command -v upower >/dev/null 2>&1; then
    echo "=== Detailed Info via upower ==="
    BAT_DEVICE=$(upower -e | grep battery | head -1)
    if [ -n "$BAT_DEVICE" ]; then
        upower -i "$BAT_DEVICE"
    else
        echo "upower found no battery devices"
    fi
else
    echo "upower not installed. For more detailed battery info, install with:"
    echo "doas apk add upower"
fi

echo
echo "Note: On PostmarketOS, battery charging is limited to ~190mA."
echo "Full fast charging requires kernel updates."
