#!/usr/bin/env bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Colors and styles
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Use alternate screen buffer to prevent flicker
tput smcup
tput civis
trap 'tput rmcup; tput cnorm; exit' INT TERM EXIT

while true; do
    tput cup 0 0
    
    # Header
    echo -e "${CYAN}${BOLD}▸ ACTIONS RUNNER CONTROLLER${NC} ${DIM}[yoga]${NC}"
    echo ""
    
    # Get data
    RUNNER_DATA=$(kubectl get autoscalingrunnersets -n arc-runners -o json 2>/dev/null)
    CONTROLLER_POD=$(kubectl get pods -n arc-systems -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    LISTENER_PODS=$(kubectl get pods -n arc-runners -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | contains("listener")) | .metadata.name' 2>/dev/null)
    
    # System status
    if [ -n "$CONTROLLER_POD" ]; then
        CTRL_STATUS=$(kubectl get pod "$CONTROLLER_POD" -n arc-systems -o jsonpath='{.status.phase}' 2>/dev/null)
        if [ "$CTRL_STATUS" = "Running" ]; then
            echo -e "${GREEN}●${NC} System operational"
        else
            echo -e "${YELLOW}◐${NC} System starting"
        fi
    else
        echo -e "${RED}●${NC} System offline"
    fi
    
    echo ""
    
    # Parse runner sets
    if [ -n "$RUNNER_DATA" ]; then
        echo "$RUNNER_DATA" | jq -c '.items[]' | while read -r item; do
            NAME=$(echo "$item" | jq -r '.metadata.name')
            REPO=$(echo "$NAME" | sed 's/^yoga-//')
            
            CURRENT=$(echo "$item" | jq -r '.status.currentRunners // 0')
            PENDING=$(echo "$item" | jq -r '.status.pendingRunners // 0')
            RUNNING=$(echo "$item" | jq -r '.status.runningRunners // 0')
            FINISHED=$(echo "$item" | jq -r '.status.finishedRunners // 0')
            
            # Repository header with status
            if [ "$RUNNING" -gt 0 ]; then
                echo -e "${BOLD}${REPO}${NC} ${GREEN}▶ ACTIVE${NC}"
            elif [ "$PENDING" -gt 0 ]; then
                echo -e "${BOLD}${REPO}${NC} ${YELLOW}◷ STARTING${NC}"
            else
                echo -e "${BOLD}${REPO}${NC} ${DIM}standby${NC}"
            fi
            
            # Only show metrics if there's activity
            if [ "$CURRENT" -gt 0 ] || [ "$PENDING" -gt 0 ] || [ "$RUNNING" -gt 0 ]; then
                if [ "$RUNNING" -gt 0 ]; then
                    echo -e "  ${GREEN}▸${NC} $RUNNING executing"
                fi
                if [ "$PENDING" -gt 0 ]; then
                    echo -e "  ${YELLOW}▸${NC} $PENDING provisioning"
                fi
                if [ "$FINISHED" -gt 0 ]; then
                    echo -e "  ${DIM}▸${NC} $FINISHED ${DIM}completed${NC}"
                fi
                echo ""
            fi
        done
        
        # Listener status (only if active)
        LISTENER_COUNT=$(echo "$LISTENER_PODS" | grep -c . 2>/dev/null || echo 0)
        if [[ "$LISTENER_COUNT" =~ ^[0-9]+$ ]] && [ "$LISTENER_COUNT" -gt 0 ]; then
            echo -e "${DIM}━━━${NC}"
            echo -e "${DIM}$LISTENER_COUNT listeners active${NC}"
            echo ""
        fi
    fi
    
    # Footer with timestamp
    echo ""
    echo -e "${DIM}$(date '+%H:%M:%S') • Press Ctrl+C to exit${NC}"
    
    sleep 0.1
done
