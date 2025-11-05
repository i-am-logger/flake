#!/usr/bin/env bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║     GitHub Actions Runner Controller - Status Monitor      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

RUNNER_SETS=$(kubectl get autoscalingrunnersets -n arc-runners -o json 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Error: Cannot connect to k3s cluster${NC}"
    exit 1
fi

echo "$RUNNER_SETS" | jq -r '.items[] | @json' | while read -r item; do
    NAME=$(echo "$item" | jq -r '.metadata.name')
    REPO=$(echo "$NAME" | sed 's/^yoga-//')
    
    CURRENT=$(echo "$item" | jq -r '.status.currentRunners // 0')
    PENDING=$(echo "$item" | jq -r '.status.pendingRunners // 0')
    RUNNING=$(echo "$item" | jq -r '.status.runningRunners // 0')
    FINISHED=$(echo "$item" | jq -r '.status.finishedRunners // 0')
    MIN=$(echo "$item" | jq -r '.spec.minRunners // "-"')
    MAX=$(echo "$item" | jq -r '.spec.maxRunners // "∞"')
    
    if [ "$RUNNING" -gt 0 ]; then
        STATUS="${GREEN}● ACTIVE${NC}"
    elif [ "$PENDING" -gt 0 ]; then
        STATUS="${YELLOW}◐ STARTING${NC}"
    else
        STATUS="${BLUE}○ IDLE${NC}"
    fi
    
    echo -e "${BOLD}Repository: ${CYAN}$REPO${NC} $STATUS"
    echo -e "  ${BOLD}Name:${NC} $NAME"
    echo -e "  ${BOLD}Scale:${NC} $MIN min → $MAX max"
    echo ""
    echo -e "  ${BOLD}Runners:${NC}"
    
    if [ "$CURRENT" -gt 0 ]; then
        echo -e "    ${GREEN}■${NC} Current:  $CURRENT"
    fi
    if [ "$RUNNING" -gt 0 ]; then
        echo -e "    ${GREEN}▶${NC} Running:  $RUNNING"
    fi
    if [ "$PENDING" -gt 0 ]; then
        echo -e "    ${YELLOW}◷${NC} Pending:  $PENDING"
    fi
    if [ "$FINISHED" -gt 0 ]; then
        echo -e "    ${BLUE}✓${NC} Finished: $FINISHED"
    fi
    if [ "$CURRENT" -eq 0 ] && [ "$PENDING" -eq 0 ]; then
        echo -e "    ${BLUE}○${NC} No active runners"
    fi
    
    echo ""
    echo "  ─────────────────────────────────────────────────────"
    echo ""
done

echo -e "${BOLD}${CYAN}Controller Status:${NC}"
CONTROLLER_POD=$(kubectl get pods -n arc-systems -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$CONTROLLER_POD" ]; then
    CONTROLLER_STATUS=$(kubectl get pod "$CONTROLLER_POD" -n arc-systems -o jsonpath='{.status.phase}' 2>/dev/null)
    CONTROLLER_READY=$(kubectl get pod "$CONTROLLER_POD" -n arc-systems -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$CONTROLLER_STATUS" = "Running" ] && [ "$CONTROLLER_READY" = "True" ]; then
        echo -e "  ${GREEN}✓${NC} ARC Controller: ${GREEN}$CONTROLLER_STATUS${NC}"
    else
        echo -e "  ${YELLOW}◐${NC} ARC Controller: ${YELLOW}$CONTROLLER_STATUS${NC}"
    fi
    
    LISTENERS=$(kubectl get pods -n arc-runners -o json 2>/dev/null | jq -r '.items[].metadata.name' 2>/dev/null | grep -c listener 2>/dev/null || echo 0)
    # Ensure LISTENERS is a valid integer
    if [[ "$LISTENERS" =~ ^[0-9]+$ ]] && [ "$LISTENERS" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Listener Pods: ${GREEN}$LISTENERS active${NC}"
    fi
else
    echo -e "  ${RED}✗${NC} ARC Controller: Not found"
fi

echo ""
echo -e "${BOLD}k3s Cluster:${NC}"
NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$NODE_STATUS" = "True" ]; then
    echo -e "  ${GREEN}✓${NC} Cluster: ${GREEN}Ready${NC}"
else
    echo -e "  ${RED}✗${NC} Cluster: ${RED}Not Ready${NC}"
fi

echo ""
echo -e "${BOLD}Commands:${NC}"
echo "  arc-status       - Show this status"
echo "  arc-watch        - Watch status (auto-refresh)"
echo "  arc-logs         - View controller logs"
echo ""
