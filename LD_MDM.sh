#!/bin/bash

# Definir códigos de color
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Función para obtener el nombre del volumen del sistema
get_system_volume() {
    system_volume=$(diskutil info / | grep "Device Node" | awk -F': ' '{print $2}' | xargs diskutil info | grep "Volume Name" | awk -F': ' '{print $2}' | tr -d ' ')
    echo "$system_volume"
}

# Obtener el nombre del volumen del sistema
system_volume=$(get_system_volume)

# Si no se puede detectar, usar "Macintosh HD" como valor predeterminado
if [ -z "$system_volume" ]; then
    system_volume="Macintosh HD"
fi

# Mostrar encabezado
echo -e "${CYAN}MDM & Notification Management Script by Assaf Dori & HR1MNA${NC}"
echo ""

# Mostrar el menú con opciones
PS3='Por favor, elige una opción: '
options=("Bypass MDM desde Recovery" "Deshabilitar Notificaciones (SIP)" "Deshabilitar Notificaciones (Recovery)" "Verificar inscripción en MDM" "Configurar Launch Daemon para Bloqueo Permanente" "Reiniciar y Salir")
select opt in "${options[@]}"; do
    case $opt in
        "Bypass MDM desde Recovery")
            echo -e "${YEL}Bypass MDM desde Recovery${NC}"
            # Verificar si la partición de datos está montada como "Macintosh HD - Data"
            if [ -d "/Volumes/$system_volume - Data" ]; then
                diskutil rename "$system_volume - Data" "Data"
            fi

            # Verificar si la ruta de usuarios existe
            dscl_path="/Volumes/Macintosh HD/private/var/db/dslocal/nodes/Default"
            if [ -d "$dscl_path" ]; then
                echo -e "${GRN}Ruta encontrada: $dscl_path${NC}"
            else
                echo -e "${RED}La ruta $dscl_path no existe.${NC}"
                exit 1
            fi

            # Crear Usuario Temporal
            echo -e "${NC}Creación de Usuario Temporal"
            read -p "Introduce el nombre completo del usuario temporal (por defecto 'Apple'): " realName
            realName="${realName:=Apple}"
            read -p "Introduce el nombre de usuario temporal (por defecto 'Apple'): " username
            username="${username:=Apple}"
            read -p "Introduce la contraseña temporal (por defecto '1234'): " passw
            passw="${passw:=1234}"

            # Crear el usuario temporal
            echo -e "${GRN}Creando el usuario temporal...${NC}"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
            mkdir "/Volumes/Macintosh HD/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
            dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
            dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username

            # Bloquear dominios MDM en /etc/hosts
            echo "Bloqueando dominios MDM en /etc/hosts..."
            sudo sed -i '' '/# MDM Servers/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/# End/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/deviceenrollment.apple.com/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/mdmenrollment.apple.com/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/iprofiles.apple.com/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/acmdm.apple.com/d' /Volumes/Macintosh\ HD/etc/hosts
            sudo sed -i '' '/axm-adm-mdm.apple.com/d' /Volumes/Macintosh\ HD/etc/hosts

            echo "# MDM Servers" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "0.0.0.0 deviceenrollment.apple.com" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "0.0.0.0 mdmenrollment.apple.com" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "0.0.0.0 iprofiles.apple.com" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "0.0.0.0 acmdm.apple.com" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "0.0.0.0 axm-adm-mdm.apple.com" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo "# End" | sudo tee -a /Volumes/Macintosh\ HD/etc/hosts
            echo -e "${GRN}Dominios MDM bloqueados exitosamente${NC}"

            # Eliminar perfiles de configuración
            echo "Eliminando perfiles de configuración..."
            touch /Volumes/Macintosh\ HD/private/var/db/.AppleSetupDone
            rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
            rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
            touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
            touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
            echo -e "${GRN}Perfiles de configuración eliminados exitosamente.${NC}"

            echo -e "${GRN}El MDM ha sido evitado exitosamente!${NC}"
            echo -e "${NC}Cierra la terminal y reinicia tu Mac.${NC}"
            break
            ;;

        "Deshabilitar Notificaciones (SIP)")
            # Deshabilitar notificaciones (SIP)
            echo -e "${RED}Introduce tu contraseña para proceder${NC}"
            sudo rm /var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
            sudo rm /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
            sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
            sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
            echo -e "${GRN}Notificaciones deshabilitadas exitosamente (SIP)${NC}"
            break
            ;;

        "Deshabilitar Notificaciones (Recovery)")
            # Deshabilitar notificaciones desde Recovery
            rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
            rm -rf /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
            touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
            touch /Volumes/Macintosh\ HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
            echo -e "${GRN}Notificaciones deshabilitadas exitosamente desde Recovery${NC}"
            break
            ;;

        "Verificar inscripción en MDM")
            # Verificar la inscripción en MDM
            echo -e "${GRN}Verificación de inscripción en MDM${NC}"
            sudo profiles show -type enrollment
            break
            ;;

        "Configurar Launch Daemon para Bloqueo Permanente")
            # Configurar Launch Daemon
            echo -e "${YEL}Configurando Launch Daemon para bloqueo permanente de dominios MDM${NC}"

            # Crear el script de bloqueo
            bloque_script="/usr/local/bin/bloquear_mdm.sh"
            echo -e "${GRN}Creando el script de bloqueo en $bloque_script${NC}"
            sudo tee "$bloque_script" > /dev/null << EOF
#!/bin/bash

# Bloquear dominios MDM en /etc/hosts
echo "Bloqueando dominios MDM en /etc/hosts..."
sudo sed -i '' '/# MDM Servers/d' /etc/hosts
sudo sed -i '' '/# End/d' /etc/hosts
sudo sed -i '' '/deviceenrollment.apple.com/d' /etc/hosts
sudo sed -i '' '/mdmenrollment.apple.com/d' /etc/hosts
sudo sed -i '' '/iprofiles.apple.com/d' /etc/hosts
sudo sed -i '' '/acmdm.apple.com/d' /etc/hosts
sudo sed -i '' '/axm-adm-mdm.apple.com/d' /etc/hosts

echo "# MDM Servers" | sudo tee -a /etc/hosts
echo "0.0.0.0 deviceenrollment.apple.com" | sudo tee -a /etc/hosts
echo "0.0.0.0 mdmenrollment.apple.com" | sudo tee -a /etc/hosts
echo "0.0.0.0 iprofiles.apple.com" | sudo tee -a /etc/hosts
echo "0.0.0.0 acmdm.apple.com" | sudo tee -a /etc/hosts
echo "0.0.0.0 axm-adm-mdm.apple.com" | sudo tee -a /etc/hosts
echo "# End" | sudo tee -a /etc/hosts
EOF

            sudo chmod +x "$bloque_script"

            # Crear el archivo plist para el Launch Daemon
            plist_file="/Library/LaunchDaemons/com.usuario.bloquear_mdm.plist"
            echo -e "${GRN}Creando el archivo plist para el Launch Daemon en $plist_file${NC}"
            sudo tee "$plist_file" > /dev/null << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.usuario.bloquear_mdm</string>
    
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string>
      <string>$bloque_script</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>StartInterval</key>
    <integer>3600</integer> <!-- Ejecuta el script cada hora -->
    
    <key>StandardOutPath</key>
    <string>/var/log/bloquear_mdm.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/bloquear_mdm.err</string>
  </dict>
</plist>
EOF

            # Establecer permisos adecuados para el plist
            echo -e "${GRN}Estableciendo permisos para el archivo plist${NC}"
            sudo chown root:wheel "$plist_file"
            sudo chmod 644 "$plist_file"

            # Cargar el Launch Daemon
            echo -e "${GRN}Cargando el Launch Daemon${NC}"
            sudo launchctl load "$plist_file"

            echo -e "${GRN}Launch Daemon configurado y cargado exitosamente.${NC}"
            echo -e "${NC}El script de bloqueo se ejecutará cada hora para mantener bloqueados los dominios MDM.${NC}"
            break
            ;;

        "Reiniciar y Salir")
            echo "Reiniciando..."
            reboot
            break
            ;;

        *) 
            echo "Opción no válida: $REPLY"
            ;;
    esac
done
