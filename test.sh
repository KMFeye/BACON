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

# --- 4. Validate Nextflow Version ---
echo -e "\n${YELLOW}4. Checking Nextflow Version...${NC}"
if command -v nextflow &> /dev/null; then
    NEXTFLOW_VERSION=$(nextflow -version 2>&1 | grep -oP 'nextflow version \K[0-9.]+')
    echo -e "  [${GREEN}OK${NC}] Nextflow version: $NEXTFLOW_VERSION"
else
    echo -e "  [${RED}FAIL${NC}] Nextflow not found in PATH"
    ERRORS=$((ERRORS+1))
fi

# --- 5. Run Nextflow Lint ---
echo -e "\n${YELLOW}5. Running Nextflow Syntax Linter...${NC}"
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

# --- 6. Validate Nextflow Configuration Syntax ---
echo -e "\n${YELLOW}6. Validating Configuration Syntax...${NC}"
if command -v nextflow &> /dev/null && [[ -f "main.nf" ]]; then
    if nextflow config -flat main.nf > /dev/null 2>&1; then
        echo -e "  [${GREEN}OK${NC}] Nextflow configuration is valid"
    else
        echo -e "  [${RED}FAIL${NC}] Configuration syntax error. Run 'nextflow config -flat main.nf' for details."
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "  [${YELLOW}SKIP${NC}] Skipping config validation because nextflow or main.nf is missing."
fi

# --- 7. Check Environment Variables ---
echo -e "\n${YELLOW}7. Checking Environment Variables...${NC}"
if [[ -z "${PATH}" ]]; then
    echo -e "  [${RED}FAIL${NC}] PATH is not set"
    ERRORS=$((ERRORS+1))
else
    echo -e "  [${GREEN}OK${NC}] PATH is set"
fi

if [[ -z "${CONDA_PREFIX}" ]]; then
    echo -e "  [${YELLOW}WARN${NC}] CONDA_PREFIX is not set. Make sure conda is activated."
else
    echo -e "  [${GREEN}OK${NC}] CONDA_PREFIX is set: $CONDA_PREFIX"
fi

# --- 8. Validate Module Files ---
echo -e "\n${YELLOW}8. Validating Module Files...${NC}"
if [[ -d "modules" ]]; then
    MODULE_COUNT=$(find modules -name "*.nf" 2>/dev/null | wc -l)
    if [[ $MODULE_COUNT -gt 0 ]]; then
        echo -e "  [${GREEN}OK${NC}] Found $MODULE_COUNT module(s)"
        # Check each module for syntax errors
        while IFS= read -r mod; do
            if nextflow lint "$mod" > /dev/null 2>&1; then
                echo -e "    [${GREEN}OK${NC}] $(basename $mod) is valid"
            else
                echo -e "    [${RED}FAIL${NC}] $(basename $mod) has syntax errors"
                ERRORS=$((ERRORS+1))
            fi
        done < <(find modules -name "*.nf")
    else
        echo -e "  [${YELLOW}WARN${NC}] No .nf files found in modules/"
    fi
else
    echo -e "  [${YELLOW}SKIP${NC}] modules/ directory not found"
fi

# --- 9. Check Input Data Configuration ---
echo -e "\n${YELLOW}9. Checking Input Data Configuration...${NC}"
if [[ -f "nextflow.config" ]]; then
    INPUT_PATH=$(grep -oP "params\.input\s*=\s*['\"]?\K[^'\"]*" nextflow.config | head -1)
    if [[ -n "$INPUT_PATH" ]]; then
        if [[ -e "$INPUT_PATH" ]]; then
            echo -e "  [${GREEN}OK${NC}] Input path exists: $INPUT_PATH"
        else
            echo -e "  [${YELLOW}WARN${NC}] Input path configured but not found: $INPUT_PATH"
        fi
    else
        echo -e "  [${YELLOW}WARN${NC}] No input path configured in nextflow.config"
    fi
else
    echo -e "  [${YELLOW}SKIP${NC}] nextflow.config not found"
fi

# --- 10. Final Report ---
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
