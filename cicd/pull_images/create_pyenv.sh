#!/bin/bash

set -e

ENV_DIR=".venv"
REQUIREMENTS_FILE="requirements.txt"

echo "🔧 Creating Python virtual environment in $ENV_DIR..."
python3 -m venv "$ENV_DIR"

echo "🐍 Activating virtual environment..."
source "$ENV_DIR/bin/activate"

echo "📦 Installing dependencies from $REQUIREMENTS_FILE..."
pip install --upgrade pip
pip install -r "$REQUIREMENTS_FILE"
