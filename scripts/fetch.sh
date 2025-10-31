#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/interview_sandbox"
# Clone using HTTPS; Git in Codespaces will prompt/SSO as the candidate.
git clone https://github.com/Bonkey-Enterprise/BonkeyWonkers.git .
printf "\nLoaded exercises into: %s\n" "$HOME/interview_sandbox"
