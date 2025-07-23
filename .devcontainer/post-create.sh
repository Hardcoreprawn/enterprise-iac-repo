#!/bin/bash

# Post-create script for infrastructure toolkit devcontainer
# Sets up the environment after container creation with repo cloned to Linux filesystem

set -e

echo "🚀 Setting up Infrastructure Toolkit devcontainer..."

# Update package lists
sudo apt-get update

# Install additional tools
echo "📦 Installing additional tools..."
sudo apt-get install -y \
    jq \
    curl \
    wget \
    unzip \
    make \
    tree \
    htop \
    nano

# Install Node.js-based tools
echo "📝 Installing markdownlint-cli..."
sudo npm install -g markdownlint-cli

# Set up PowerShell repository for on-demand module installation
echo "🔧 Configuring PowerShell repository..."
pwsh -c 'Set-PSRepository PSGallery -InstallationPolicy Trusted'

# Set up git configuration (if not already set)
echo "🔧 Configuring git..."
if [ ! -f ~/.gitconfig ]; then
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
fi

# Make PowerShell scripts executable
echo "🔧 Setting up PowerShell scripts..."
find /workspaces/enterprise-iac-repo -name "*.ps1" -type f -exec chmod +x {} \;

# Run the toolkit setup
echo "🔧 Running toolkit setup..."
cd /workspaces/enterprise-iac-repo
pwsh -ExecutionPolicy Bypass -File "./setup.ps1" -Minimal -Force

# Install git hooks
echo "🪝 Installing git hooks..."
if [ -d ".git" ]; then
    make install-hooks || echo "⚠️  Git hooks installation skipped (will work after first commit)"
fi

# Create performance optimization message
echo "⚡ Performance Note:"
echo "   Repository is running on Linux filesystem for optimal performance"
echo "   Terraform operations will be significantly faster than Windows bind mount"
echo ""

# Create a welcome message
echo "✅ Devcontainer setup complete!"
echo ""
echo "🎯 Quick Start Commands:"
echo "  make help           - Show all available commands"
echo "  make validate-dry   - Quick validation test"
echo "  ./setup.ps1         - Re-run setup if needed"
echo ""
echo "🔐 Azure Authentication:"
echo "  az login            - Sign in to Azure"
echo "  az account list     - List available subscriptions"
echo ""
echo "📝 Configuration:"
echo "  Edit local-validation-config.json to customize for your environment"
echo ""

# Create a simple health check script
cat > /workspaces/enterprise-iac-repo/health-check.sh << 'EOF'
#!/bin/bash
echo "🏥 Infrastructure Toolkit Health Check"
echo "======================================"
echo ""

# Check filesystem type for performance info
echo "📁 Filesystem: $(df -T /workspaces | tail -n1 | awk '{print $2}')"
echo ""

# Check PowerShell
if command -v pwsh &> /dev/null; then
    echo "✅ PowerShell: $(pwsh --version)"
else
    echo "❌ PowerShell: Not found"
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    echo "✅ Azure CLI: $(az version --query '\"azure-cli\"' -o tsv)"
else
    echo "❌ Azure CLI: Not found"
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    echo "✅ Terraform: $(terraform version -json | jq -r '.terraform_version')"
else
    echo "❌ Terraform: Not found"
fi

# Check Make
if command -v make &> /dev/null; then
    echo "✅ Make: Available"
else
    echo "❌ Make: Not found"
fi

# Check Azure PowerShell repository
if pwsh -c "Get-PSRepository PSGallery | Where-Object InstallationPolicy -eq 'Trusted'" &> /dev/null; then
    echo "✅ Azure PowerShell: Repository configured (modules install on-demand)"
else
    echo "❌ Azure PowerShell: Repository not configured"
fi

echo ""
echo "⚡ Performance optimized - running on Linux filesystem!"
echo "🎯 Ready to use the Infrastructure Toolkit!"
EOF

chmod +x /workspaces/enterprise-iac-repo/health-check.sh

echo "🎉 Setup completed successfully!"
echo "Run './health-check.sh' to verify everything is working correctly."
