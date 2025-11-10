#!/usr/bin/bash

################################################
##### Android Development
################################################

print_section "Android Development Tools"

################################################
##### Android udev rules
################################################

print_info "Setting up Android udev rules"

# Create Android SDK directory
mkdir -p ${HOME}/.devtools/android

# Android udev rules
git clone https://github.com/M0Rf30/android-udev-rules.git ${HOME}/.devtools/android/udev-rules

# Install udev rules
sudo ln -sf ${HOME}/.devtools/android/udev-rules/51-android.rules /etc/udev/rules.d/51-android.rules
sudo chmod a+r /etc/udev/rules.d/51-android.rules

# Create adbusers group
sudo groupadd adbusers

# Add user to the adbusers group
sudo gpasswd -a ${USER} adbusers

# Android udev rules updater
append_to_updater '
################################################
##### Android udev rules
################################################

# Update Android udev rules
git -C ${HOME}/.devtools/android/udev-rules pull
'

################################################
##### Android SDK tools
################################################

print_info "Installing Android SDK tools"

# Create Android SDK directory
mkdir -p ${HOME}/.devtools/android

# Install Android SDK command line tools
CMDLINE_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r .version)
curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_LATEST_VERSION}_latest.zip -O
unzip commandlinetools-linux-*_latest.zip -d ${HOME}/.devtools/android
rm -f commandlinetools-linux-*.zip
echo ${CMDLINE_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/cmdline_tools_installed_version

# Accept sdkmanager licenses
yes | ${HOME}/.devtools/android/cmdline-tools/bin/sdkmanager --sdk_root=${HOME}/.devtools/android --licenses

# Install Android SDK platform tools
PLATFORM_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-platform-tools.json | jq -r .version)
curl -sSL https://dl.google.com/android/repository/platform-tools_r${PLATFORM_TOOLS_LATEST_VERSION}-linux.zip -O
unzip platform-tools_r*-linux.zip -d ${HOME}/.devtools/android
rm -f platform-tools_r*-linux.zip
echo ${PLATFORM_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/platform_tools_installed_version

# Set env vars and paths
create_zsh_config "android" "# Android env vars
export ANDROID_HOME='${HOME}/.devtools/android'
export ANDROID_SDK_ROOT='${HOME}/.devtools/android'

# Add tools to path
export PATH=\"\${PATH}:\${ANDROID_HOME}/platform-tools\"
export PATH=\"\${PATH}:\${ANDROID_HOME}/cmdline-tools/bin\""

# Android tools updater
append_to_updater '
################################################
##### Android SDK tools
################################################

# cmdline tools versions
INSTALLED_CMDLINE_TOOLS_VERSION=$(cat ${HOME}/.devtools/android/cmdline_tools_installed_version)
CMDLINE_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r .version)

# platform tools versions
INSTALLED_PLATFORM_TOOLS_VERSION=$(cat ${HOME}/.devtools/android/platform_tools_installed_version)
PLATFORM_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-platform-tools.json | jq -r .version)

# Update cmdline tools
if [[ "${INSTALLED_CMDLINE_TOOLS_VERSION}" != "${CMDLINE_TOOLS_LATEST_VERSION}" ]]; then
  curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_LATEST_VERSION}_latest.zip -O
  rm -rf ${HOME}/.devtools/android/cmdline-tools
  unzip commandlinetools-linux-*_latest.zip -d ${HOME}/.devtools/android
  rm -f commandlinetools-linux-*.zip
  echo ${CMDLINE_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/cmdline_tools_installed_version
fi

# Update platform tools
if [[ "${INSTALLED_PLATFORM_TOOLS_VERSION}" != "${PLATFORM_TOOLS_LATEST_VERSION}" ]]; then
  curl -sSL https://dl.google.com/android/repository/platform-tools_r${PLATFORM_TOOLS_LATEST_VERSION}-linux.zip -O
  rm -rf ${HOME}/.devtools/android/platform-tools
  unzip platform-tools_r*-linux.zip -d ${HOME}/.devtools/android
  rm -f platform-tools_r*-linux.zip
  echo ${PLATFORM_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/platform_tools_installed_version
fi
'

print_info "Android development tools installation completed"