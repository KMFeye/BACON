#!/bin/bash

# --- Color Codes for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}   Pipeline Pre-Flight Validation Check               ${NC}"
echo -e "${GREEN}======================================================${NC}\n"

ERRORS=0

# --- 1. Check Core Software Dependencies ---
echo -e "${YELLOW}1. Checking Core Software...${NC}"
for cmd in nextflow conda java curl jq; do
    if command -v $cmd &> /dev/null; then
        echo -e "  [${GREEN}OK${NC}] $cmd is installed: $(command -v $cmd)"
    else
        echo -e "  [${RED}FAIL${NC}] $cmd is missing! Please install it or load the module."
        ERRORS=$((ERRORS+1))
    fi
done

# --- 2. Check Pipeline Directory Structure ---
echo -e "\n${YELLOW}2. Checking Pipeline Structure...${NC}"
for file in main.nf nextflow.config; do
    if [[ -f "$file" ]]; then
        echo -e "  [${GREEN}OK${NC}] Found $file"
    else
        echo -e "  [${RED}FAIL${NC}] Missing $file in the current directory!"
        ERRORS=$((ERRORS+1))
    fi
done

for dir in modules; do
    if [[ -d "$dir" ]]; then
        echo -e "  [${GREEN}OK${NC}] Found $dir/ directory"
    else
        echo -e "  [${RED}FAIL${NC}] Missing $dir/ directory!"
        ERRORS=$((ERRORS+1))
    fi
done

# --- 3. Check for common configuration issues ---
echo -e "\n${YELLOW}3. Checking Configuration...${NC}"
if grep -q "conda.channels" nextflow.config; then
    echo -e "  [${GREEN}OK${NC}] Conda channels are configured in nextflow.config"
else
    echo -e "  [${YELLOW}WARN${NC}] No conda channels explicitly defined in nextflow.config. Make sure your local conda is configured correctly."
fi

# --- 4. Run Nextflow Lint ---
echo -e "\n${YELLOW}4. Running Nextflow Syntax Linter...${NC}"
if command -v nextflow &> /dev/null && [[ -f "main.nf" ]]; then
    # Run lint and suppress the standard output, only capturing exit code
    if nextflow lint main.nf > /dev/null 2>&1; then
         echo -e "  [${GREEN}OK${NC}] Nextflow lint passed with no fatal errors."
    else
         echo -e "  [${RED}FAIL${NC}] Nextflow lint found structural errors. Run 'nextflow lint main.nf' manually to see them."
         ERRORS=$((ERRORS+1))
    fi
else
    echo -e "  [${YELLOW}SKIP${NC}] Skipping lint because nextflow or main.nf is missing."
fi

# --- 5. Final Report ---
echo -e "\n${GREEN}======================================================${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}SUCCESS! All pre-flight checks passed.${NC}"
    echo -e "You are ready to run: ${YELLOW}nextflow run main.nf -resume${NC}"
else
    echo -e "${RED}WARNING: Found $ERRORS error(s).${NC}"
    echo -e "Please fix the issues above before running the pipeline."
    exit 1
fi
echo -e "${GREEN}======================================================${NC}\n"
