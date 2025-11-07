#!/bin/bash
echo "🚀 Starting Flutter Development Environment Setup"
# Phase 1: Flutter SDK
echo "📥 Downloading Flutter SDK..."
cd ~/Downloads
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz
tar -xf flutter_linux_3.19.6-stable.tar.xz
mv flutter ~/development/
# Update PATH
echo 'export PATH="$PATH:~/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
echo "✅ Flutter SDK installed"
# Phase 2: Android Setup
echo "📱 Setting up Android development..."
sudo apt update
sudo apt install -y openjdk-11-jdk
# Download Android Studio
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.2.1.24/android-studio-2023.2.1.24-linux.tar.gz
sudo tar -xzf android-studio-*-linux.tar.gz -C /opt/
echo "✅ Android development tools installed"
# Phase 3: VS Code
echo "💻 Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code
echo "✅ VS Code installed"
echo "🎉 Setup complete! Run 'flutter doctor' to verify installation"
