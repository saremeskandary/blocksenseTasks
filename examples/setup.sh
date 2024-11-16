#!/bin/bash
# Create project structure
mkdir -p price_consumer/src
mkdir -p price_consumer/test
mkdir -p price_consumer/script

# Create foundry.toml
cat > price_consumer/foundry.toml << 'EOF'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
evm_version = "paris"

[rpc_endpoints]
anvil = "http://localhost:8545"
EOF

# Create Cargo.toml for remappings
cat > price_consumer/.gitignore << 'EOF'
# Compiler files
cache/
out/

# Ignores development broadcast logs
!/broadcast
/broadcast/*/31337/
/broadcast/**/dry-run/

# Docs
docs/

# Dotenv file
.env
EOF

# Create remappings.txt
cat > price_consumer/remappings.txt << 'EOF'
ds-test/=lib/forge-std/lib/ds-test/src/
forge-std/=lib/forge-std/src/
EOF