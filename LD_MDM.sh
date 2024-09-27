#!/bin/bash

# Global Constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_USER_FULL_NAME="EightAugusto"
readonly DEFAULT_USER_NAME="EightAugusto"
readonly DEFAULT_USER_PASSWORD=""
readonly APPLE_MDM_DOMAINS=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")

# Ruta del script y archivo .plist
SCRIPT_PATH="/usr/local/bin/mdm_bypass.sh"
PLIST_PATH="/Library/LaunchDaemons/com.eightaugusto.mdm_bypass.plist"

# Función para verificar si existe un volumen
check_volume_existence() {
  local VOLUME_LABEL="$*"
  diskutil info "${VOLUME_LABEL}" >/dev/null 2>&1
}

# Función para obtener el nombre del volumen
get_volume_name() {
  local VOLUME_TYPE=${1}
  APFS_CONTAINER=$(diskutil list internal physical | grep 'Container' | awk -F'Container ' '{print $2}' | awk '{print $1}')
  VOLUME_INFO=$(diskutil ap list "${APFS_CONTAINER}" | grep -A 5 "($VOLUME_TYPE)")
  VOLUME_NAME_LINE=$(echo "${VOLUME_INFO}" | grep 'Name:')
  VOLUME_NAME=$(echo "${VOLUME_NAME_LINE}" | cut -d':' -f2 | cut -d'(' -f1 | xargs)
  echo ${VOLUME_NAME}
}

# Función para obtener la ruta del volumen
get_volume_path() {
  local DEFAULT_VOLUME=${1}
  local VOLUME_TYPE=${2}
  if check_volume_existence "${DEFAULT_VOLUME}"; then
    echo "/Volumes/${DEFAULT_VOLUME}"
  else
    local VOLUME_NAME
    VOLUME_NAME="$(get_volume_name "${VOLUME_TYPE}")"
    echo "/Volumes/${VOLUME_NAME}"
  fi
}

# Función para montar el volumen
mount_volume() {
  local VOLUME_PATH=${1}
  if [ ! -d ${VOLUME_PATH} ]; then
    diskutil mount ${VOLUME_PATH}
  fi
}

# Crear el archivo del Launch Daemon
create_launch_daemon() {
  echo "Creando el archivo .plist del Launch Daemon..."
  cat <<EOL | sudo tee "${PLIST_PATH}" >/dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.eightaugusto.mdm_bypass</string>
    <key>ProgramArguments</key>
    <array>
      <string>${SCRIPT_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/mdm_bypass.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/mdm_bypass.err</string>
    <key>UserName</key>
    <string>root</string>
  </dict>
</plist>
EOL

  sudo chown root:wheel "${PLIST_PATH}"
  sudo chmod 644 "${PLIST_PATH}"
}

# Crear el script original
create_script() {
  echo "Creando el script principal en ${SCRIPT_PATH}..."
  cat <<EOL | sudo tee "${SCRIPT_PATH}" >/dev/null
#!/bin/bash

PS3="Please enter your choice: "
OPTIONS=("Mac MDM Bypass" "Check MDM Enrollment" "Reboot" "Exit")
select OPTION in "\${OPTIONS[@]}"; do
  case \${OPTION} in
  "Mac MDM Bypass")
    read -rp "System volume name (Default '${DEFAULT_SYSTEM_VOLUME}'): " SYSTEM_VOLUME_NAME
    SYSTEM_VOLUME_NAME="\${SYSTEM_VOLUME_NAME:=${DEFAULT_SYSTEM_VOLUME}}"
    SYSTEM_VOLUME_PATH=\$(get_volume_path "\${SYSTEM_VOLUME_NAME}" "System")
    echo "Mounting system volume '\${SYSTEM_VOLUME_NAME}' in path '\${SYSTEM_VOLUME_PATH}'"
    mount_volume \${SYSTEM_VOLUME_PATH}
    read -rp "Data volume name (Default '${DEFAULT_SYSTEM_VOLUME} - Data'): " DATA_VOLUME_NAME
    DATA_VOLUME_NAME="\${DATA_VOLUME_NAME:="${DEFAULT_SYSTEM_VOLUME} - Data"}"
    DATA_VOLUME_PATH=\$(get_volume_path "\${DEFAULT_DATA_VOLUME}" "Data")
    echo "Mounting data volume '\${SYSTEM_VOLUME_NAME}' in path '\${SYSTEM_VOLUME_PATH}'"
    mount_volume \${DATA_VOLUME_PATH}

    echo "Checking user existence"
    DSCL_PATH="\${DATA_VOLUME_PATH}/private/var/db/dslocal/nodes/Default"
    LOCAL_USER_PATH="/Local/Default/Users"
    DEFAULT_USER_UID="501"
    if ! dscl -f "\${DSCL_PATH}" localhost -list "\${LOCAL_USER_PATH}" UniqueID | grep -q "\\<\${DEFAULT_USER_UID}\\>"; then
      echo "Provide new user information"
      read -rp "Full name (Default '${DEFAULT_USER_FULL_NAME}'): " USER_FULL_NAME
      USER_FULL_NAME="\${USER_FULL_NAME:=${DEFAULT_USER_FULL_NAME}}"
      read -rp "User name (Default '${DEFAULT_USER_NAME}'): " USER_NAME
      USER_NAME="\${username:=${DEFAULT_USER_NAME}}"
      read -rp "Password: '${DEFAULT_USER_PASSWORD}'" USER_PASSWORD
      USER_PASSWORD="\${USER_PASSWORD:=${DEFAULT_USER_PASSWORD}}"

      echo "Creating user '\${USER_NAME}' path '\${DATA_VOLUME_PATH}/Users/\${USER_NAME}' for '\${USER_FULL_NAME}'"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}" UserShell "/bin/zsh"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}" RealName "\${USER_FULL_NAME}"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}" UniqueID "\${DEFAULT_USER_UID}"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}" PrimaryGroupID "20"
      mkdir "\${DATA_VOLUME_PATH}/Users/\${USER_NAME}"
      dscl -f "\${DSCL_PATH}" localhost -create "\${LOCAL_USER_PATH}/\${USER_NAME}" NFSHomeDirectory "/Users/\${USER_NAME}"
      dscl -f "\${DSCL_PATH}" localhost -passwd "\${LOCAL_USER_PATH}/\${USER_NAME}" "\${USER_PASSWORD}"
      dscl -f "\${DSCL_PATH}" localhost -append "/Local/Default/Groups/admin" GroupMembership "\${USER_NAME}"
    else
      echo "User already exists"
    fi

    echo "Blocking MDM hosts"
    HOST_PATH="\${SYSTEM_VOLUME_PATH}/etc/hosts"
    for DOMAIN in "${APPLE_MDM_DOMAINS[@]}"; do
      echo "0.0.0.0 \${DOMAIN}" >> \${HOST_PATH}
    done
    echo "Successfully blocked hosts"
    
    CONFIGURATION_PROFILES_PATH="\${SYSTEM_VOLUME_PATH}/var/db/ConfigurationProfiles/Settings"
    touch "\${DATA_VOLUME_PATH}/private/var/db/.AppleSetupDone"
    rm -rf "\${CONFIGURATION_PROFILES_PATH}/.cloudConfigHasActivationRecord"
    rm -rf "\${CONFIGURATION_PROFILES_PATH}/.cloudConfigRecordFound"
    touch "\${CONFIGURATION_PROFILES_PATH}/.cloudConfigProfileInstalled"
    touch "\${CONFIGURATION_PROFILES_PATH}/.cloudConfigRecordNotFound"
    echo "Configuration profiles removed"
    echo "Mac MDM Bypass finished"
    break
    ;;
    
  "Check MDM Enrollment")
    if [ ! -f /usr/bin/profiles ]; then echo "Check MDM Enrollment should not be executed in recovery mode"; continue; fi
    if ! sudo profiles show -type enrollment >/dev/null 2>&1; then echo "Not enrolled"; else echo "Enrolled"; fi
    ;;
  "Reboot") echo "Rebooting"; reboot;;
  "Exit") echo "Exiting"; exit;;
  *) echo "Invalid option: '\${REPLY}'";;
  esac
done
EOL

  sudo chmod +x "${SCRIPT_PATH}"
}

# Cargar el Launch Daemon
load_launch_daemon() {
  echo "Cargando el Launch Daemon..."
  sudo launchctl load "${PLIST_PATH}"
}

# Ejecutar todas las funciones
create_script
create_launch_daemon
load_launch_daemon

echo "Script y Launch Daemon configurados y ejecutándose correctamente."

