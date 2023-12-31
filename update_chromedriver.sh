#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to get the architecture of the current system
get_architecture() {
  uname -m
}

# Function to get the installed version of ChromeDriver
get_installed_version() {
  chromedriver --version 2>/dev/null | awk '{print $2}'
}

# Function to check if the latest version of ChromeDriver is installed
latest_version_installed() {
  if ! command_exists chromedriver; then
    echo "ChromeDriver is not installed."
    return 1
  fi

  local installed_version=$(get_installed_version)
  local latest_version=$(get_latest_version)
  echo "Your current version of ChromeDriver is $installed_version."
  echo "The latest version available is $latest_version."
  [ "$installed_version" == "$latest_version" ]
}

# Function to determine the appropriate ChromeDriver URL basd on the architecture
get_chrome_driver_url() {
  local ARCHITECTURE="$1"
  local LATEST_VERSION="$2"

  if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    echo "https://chromedriver.storage.googleapis.com/$LATEST_VERSION/chromedriver_mac64.zip"
  elif [[ "$ARCHITECTURE" == "arm64" ]]; then
    echo "https://chromedriver.storage.googleapis.com/$LATEST_VERSION/chromedriver_mac_arm64.zip"
  else
    echo "Error: Unsupported architecture: $ARCHITECTURE"
    exit 1
  fi
}

# Function to get the latest version of ChromeDriver
get_latest_version() {
  LATEST_VERSION=$(curl -sS "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")
  echo "$LATEST_VERSION"
}

# Function to download and install the latest version of ChromeDriver
install_latest_version() {
  local LATEST_VERSION=$(get_latest_version)
  local ARCHITECTURE=$(get_architecture)

  local CHROME_DRIVER_URL=$(get_chrome_driver_url "$ARCHITECTURE" "$LATEST_VERSION")
  local TMPDIR=$(mktemp -d)

  echo "Downloading ChromeDriver version $LATEST_VERSION..."
  curl -L "$CHROME_DRIVER_URL" -o "$TMPDIR/chromedriver.zip"

  if [ $? -eq 0 ]; then
    echo "Extracting..."
    unzip -q "$TMPDIR/chromedriver.zip" -d "$TMPDIR"
    sudo mv "$TMPDIR/chromedriver" "/usr/local/bin/chromedriver"
    sudo chown root:wheel "/usr/local/bin/chromedriver"
    sudo chmod +x "/usr/local/bin/chromedriver"

    if [ $? -eq 0 ]; then
      echo "Latest ChromeDriver version installed successfully."
    else
      echo "Error: Failed to install ChromeDriver version $LATEST_VERSION."
    fi
  else
    echo "Error: Failed to download ChromeDriver."
  fi

  rm -rf "$TMPDIR"

}

# Check if curl and unzip commands are available
if ! command_exists curl || ! command_exists unzip; then
  echo "Error: This script requires 'curl' and 'unzip' commands to be installed."
  exit 1
fi

# Check if ChromeDriver is already installed
if latest_version_installed; then
  echo "You already have the latest version of ChromeDriver."
  exit 0
fi

# Verify that the user wants to install the latest version of ChromeDriver
echo "Do you want to install the latest version? (y/n)"
read -r choice
if [[ $choice =~ ^[Yy]$ ]]; then
  install_latest_version
else
  echo "Exiting without installing ChromeDriver."
  exit 0
fi