################################################
##### Wine GE
################################################

# https://github.com/GloriousEggroll/wine-ge-custom

LATEST_WINE_GE_VERSION=$(curl -s https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LUTRIS_WINE_GE_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runners/wine"

# Create Lutris Wine GE folder
mkdir -p ${LUTRIS_WINE_GE_FOLDER}

# Download latest Wine GE version
curl https://github.com/GloriousEggroll/wine-ge-custom/releases/latest/download/wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz -L -O

# Extract Wine GE to Lutris folder
tar -xf wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz -C ${LUTRIS_WINE_GE_FOLDER}

# Remove downloaded Wine GE tar
rm -f wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz

################################################
##### DXVK
################################################

# https://github.com/doitsujin/dxvk

LATEST_DXVK_VERSION=$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
LUTRIS_DXVK_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/dxvk"

# Create Lutris DXVK folder
mkdir -p ${LUTRIS_DXVK_FOLDER}

# Download latest DXVK version
curl https://github.com/doitsujin/dxvk/releases/latest/download/dxvk-${LATEST_DXVK_VERSION}.tar.gz -L -O

# Extract DXVK to Lutris folder
tar -xzf dxvk-${LATEST_DXVK_VERSION}.tar.gz -C ${LUTRIS_DXVK_FOLDER}

# Rename DXVK folder
mv ${LUTRIS_DXVK_FOLDER}/dxvk-${LATEST_DXVK_VERSION} ${LUTRIS_DXVK_FOLDER}/v${LATEST_DXVK_VERSION}

# Remove downloaded DXVK tar
rm -f dxvk-${LATEST_DXVK_VERSION}.tar.gz

################################################
##### VKD3D
################################################

# https://github.com/HansKristian-Work/vkd3d-proton

LATEST_VKD3D_VERSION=$(curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
LUTRIS_VKD3D_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/vkd3d"

# Create Lutris VKD3D folder
mkdir -p ${LUTRIS_VKD3D_FOLDER}

# Download latest VKD3D version
curl https://github.com/HansKristian-Work/vkd3d-proton/releases/latest/download/vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -L -O

# Extract VKD3D to Lutris folder
tar -xf vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -C ${LUTRIS_VKD3D_FOLDER}

# Rename VKD3D folder
mv ${LUTRIS_VKD3D_FOLDER}/vkd3d-proton-${LATEST_VKD3D_VERSION} ${LUTRIS_VKD3D_FOLDER}/v${LATEST_VKD3D_VERSION}

# Remove downloaded VKD3D tar
rm -f vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst

################################################
##### Winetricks
################################################

# https://github.com/Winetricks/winetricks

LATEST_WINETRICKS_VERSION=$(curl -s https://api.github.com/repos/Winetricks/winetricks/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LUTRIS_WINETRICKS_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/winetricks"

# Create Lutris Winetricks folder
mkdir -p ${LUTRIS_WINETRICKS_FOLDER}

# Download latest Winetricks version
curl https://github.com/Winetricks/winetricks/archive/refs/tags/${LATEST_WINETRICKS_VERSION}.tar.gz -L -O

# Extract Winetricks to Lutris folder
tar -xzf ${LATEST_WINETRICKS_VERSION}.tar.gz -C ${LUTRIS_WINETRICKS_FOLDER} winetricks-${LATEST_WINETRICKS_VERSION}/src/winetricks --strip-components 2

# Remove downloaded Winetricks tar
rm -f ${LATEST_WINETRICKS_VERSION}.tar.gz

################################################
##### dgVoodoo2
################################################

# https://github.com/dege-diosg/dgVoodoo2

LATEST_DGVOODOO2_VERSION_DOTS=$(curl -s https://api.github.com/repos/dege-diosg/dgVoodoo2/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LATEST_DGVOODOO2_VERSION=$(curl -s https://api.github.com/repos/dege-diosg/dgVoodoo2/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//' | tr '.' '_')
LUTRIS_DGVOODOO2_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/dgvoodoo2"

# Create Lutris dgVoodoo2 folder
mkdir -p ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32

# Download latest dgVoodoo2 version
curl https://github.com/dege-diosg/dgVoodoo2/releases/latest/download/dgVoodoo${LATEST_DGVOODOO2_VERSION}.zip -L -O

# Extract dgVoodoo2 to Lutris folder
unzip -j dgVoodoo2_81_3.zip 3Dfx/x86/Glide* -d ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32
unzip -j dgVoodoo2_81_3.zip MS/x86/* -d ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32

# Create dgVoodoo2 config file
tee ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/dgVoodoo.conf << 'EOF'
[General]

OutputAPI                            = d3d11_fl11_0

[Glide]

3DfxWatermark                       = false
3DfxSplashScreen                    = false

[DirectX]

dgVoodooWatermark                   = false
EOF

# Remove downloaded dgVoodoo2 zip
rm -f dgVoodoo${LATEST_DGVOODOO2_VERSION}.zip