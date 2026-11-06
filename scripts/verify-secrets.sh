#!/usr/bin/env bash
# ==============================================================================
# Indonesia Law — Secret Verification Script
# ==============================================================================
# Use this script locally or in CI/pre-commit to ensure no credentials,
# environment variables, or private keys are staged or tracked in git.
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

echo "🔍 Running secret verification scan..."

# 1. Check if .gitignore properly ignores .env
if ! git check-ignore -q .env 2>/dev/null; then
    # Try touching a temporary test if .env doesn't exist yet
    if ! git check-ignore -q .env; then
        echo -e "${RED}[ERROR] .env is NOT ignored by .gitignore!${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 2. Check for tracked .env files in git index
TRACKED_ENV=$(git ls-files | grep -E '(^|/)\.env(\..+)?$' | grep -v '\.env\.example$' || true)
if [ -n "$TRACKED_ENV" ]; then
    echo -e "${RED}[ERROR] Tracked .env files found in git repository:${NC}"
    echo "$TRACKED_ENV"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check for private keys and certificates tracked
TRACKED_KEYS=$(git ls-files | grep -E '\.(key|pem|p12|pfx|pkcs12|secret|token)$' || true)
if [ -n "$TRACKED_KEYS" ]; then
    echo -e "${RED}[ERROR] Tracked private keys/tokens found in git repository:${NC}"
    echo "$TRACKED_KEYS"
    ERRORS=$((ERRORS + 1))
fi

# 4. Scan staged diff for potential high-risk keywords/patterns
STAGED_DIFF=$(git diff --cached --name-only 2>/dev/null || true)
if [ -n "$STAGED_DIFF" ]; then
    echo "Scanning staged files..."
    if git diff --cached | grep -Ei '([A-Za-z0-9_-]{32,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH|DSA|PGP)? PRIVATE KEY)' | grep -v '\.env\.example' > /dev/null 2>&1; then
        echo -e "${YELLOW}[WARNING] Potential high-entropy key or private key header found in staged changes!${NC}"
        echo -e "${YELLOW}Please inspect 'git diff --cached' carefully before committing.${NC}"
    fi
fi

if [ "$ERRORS" -gt 0 ]; then
    echo -e "\n${RED}❌ Secret verification FAILED with $ERRORS error(s). Please fix the issues above before proceeding.${NC}"
    exit 1
else
    echo -e "\n${GREEN}✅ Secret verification PASSED. No secrets or tracked .env files detected.${NC}"
    exit 0
fi

