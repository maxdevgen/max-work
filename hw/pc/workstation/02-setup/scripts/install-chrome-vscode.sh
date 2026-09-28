#!/usr/bin/env bash
# Google Chrome + VS Code — Debian 13, styl podle NUC14 (viz Nuc14/RUNBOOK.md §7)
# Spustit jako: chmod +x install-chrome-vscode.sh && ./install-chrome-vscode.sh
set -euo pipefail

sudo install -d -m 0755 /etc/apt/keyrings

# Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list

# VS Code
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- \
  | sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list

sudo apt update
sudo apt install -y google-chrome-stable code

# VS Code rozšíření (stejná sada jako NUC14)
code --install-extension anthropic.claude-code
code --install-extension github.copilot-chat

# Git (stejná identita jako NUC14)
sudo apt install -y git
git config --global user.name "Zbynek"
git config --global user.email "z.kojecky@gmail.com"
git config --global init.defaultBranch main

echo "Hotovo: Chrome, VS Code (+ rozšíření), Git nakonfigurováno."
