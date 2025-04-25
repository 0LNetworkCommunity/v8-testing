#!/bin/bash

# The command to run every 5 minutes
# Replace this with your actual command that calls get_current_roots_at_registry
COMMAND="libra txs -m=\"$MNEM\" governance epoch-boundary"

# Print startup message
echo "Starting script at $(date)"
echo "Will run command every 5 minutes. Press Ctrl+C to stop."
echo "----------------------------------------"

# Infinite loop that runs the command and sleeps for 5 minutes
while true; do
    # Run the command (using eval to interpret the command string)
    eval "$COMMAND" || echo "Command failed, but continuing execution."
    echo "----------------------------------------"

    # Sleep for 5 minutes (300 seconds)
    sleep 300
done
