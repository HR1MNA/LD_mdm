#!/bin/bash

# Definir códigos de color
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Mostrar encabezado
echo -e "${CYAN}MDM & Notification Management Script by Assaf Dori & HR1MNA${NC}"
echo ""

# Función para mostrar el menú de nuevo
mostrar_menu() {
    PS3='Por favor, elige una opción: '
    options=("Bypass MDM desde Recovery" "Deshabilitar Notificaciones (SIP)" "Deshabilitar Notificaciones (Recovery)" "Verificar inscripción en MDM" "Configurar Launch Daemon para Bloqueo Permanente" "Reiniciar y Salir")
    select opt in "${options[@]}"; do
        case $opt in
            "Bypass MDM desde Recovery")
                echo -e "${YEL}Bypass MDM desde Recovery${NC}"
                system_volume="/Volumes/macOS Base System"

                # Verificar si la partición de datos está montada
                if [ -d "$system_volume - Data" ]; then
                    diskutil rename "$system_volume - Data" "Data"
                fi

                # Verificar si la carpeta de usuario ya existe
                if [ ! -d "$system_volume/Users/Apple" ]; then
                    mkdir "$system_volume/Users/Apple"
                else
                    echo -e "${YEL}El directorio $system_volume/Users/Apple ya existe.${NC}"
                fi

                # Bloquear dominios MDM en /etc/hosts
                echo "Bloqueando dominios MDM en /etc/hosts..."
                if ! grep -q "deviceenrollment.apple.com" "$system_volume/etc/hosts"; then
                    echo "0.0.0.0 deviceenrollment.apple.com" >> "$system_volume/etc/hosts"
                fi
                if ! grep -q "mdmenrollment.apple.com" "$system_volume/etc/hosts"; then
                    echo "0.0.0.0 mdmenrollment.apple.com" >> "$system_volume/etc/hosts"
                fi
                if ! grep -q "iprofiles.apple.com" "$system_volume/etc/hosts"; then
                    echo "0.0.0.0 iprofiles.apple.com" >> "$system_volume/etc/hosts"
                fi
                if ! grep -q "acmdm.apple.com" "$system_volume/etc/hosts"; then
                    echo "0.0.0.0 acmdm.apple.com" >> "$system_volume/etc/hosts"
                fi
                if ! grep -q "axm-adm-mdm.apple.com" "$system_volume/etc/hosts"; then
                    echo "0.0.0.0 axm-adm-mdm.apple.com" >> "$system_volume/etc/hosts"
                fi

                echo -e "${GRN}Dominios MDM bloqueados exitosamente${NC}"

                # Eliminar perfiles de configuración
                echo "Eliminando perfiles de configuración..."
                touch "$system_volume/private/var/db/.AppleSetupDone"
                rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
                rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
                touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
                touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"
                echo -e "${GRN}Perfiles de configuración eliminados exitosamente.${NC}"

                echo -e "${GRN}El MDM ha sido evitado exitosamente!${NC}"
                echo -e "${NC}Cierra la terminal y reinicia tu Mac.${NC}"
                mostrar_menu # Volver a mostrar el menú
                ;;

            "Deshabilitar Notificaciones (SIP)")
                echo -e "${RED}Introduce tu contraseña para proceder${NC}"
                rm /var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
                rm /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
                touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
                touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
                echo -e "${GRN}Notificaciones deshabilitadas exitosamente (SIP)${NC}"
                mostrar_menu # Volver a mostrar el menú
                ;;

            "Deshabilitar Notificaciones (Recovery)")
                rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
                rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
                touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
                touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"
                echo -e "${GRN}Notificaciones deshabilitadas exitosamente desde Recovery${NC}"
                mostrar_menu # Volver a mostrar el menú
                ;;

            "Verificar inscripción en MDM")
                echo -e "${GRN}Verificación de inscripción en MDM${NC}"
                profiles show -type enrollment
                mostrar_menu # Volver a mostrar el menú
                ;;

            "Configurar Launch Daemon para Bloqueo Permanente")
                if [ ! -d "/usr/local/bin" ]; then
                    echo "Creando el directorio /usr/local/bin"
                    mkdir -p /usr/local/bin
                fi

                bloque_script="/usr/local/bin/bloquear_mdm.sh"
                echo -e "${GRN}Creando el script de bloqueo en $bloque_script${NC}"
                tee "$bloque_script" > /dev/null << EOF
#!/bin/bash

system_volume="/Volumes/macOS Base System"
echo "Bloqueando dominios MDM en /etc/hosts..."
if ! grep -q "deviceenrollment.apple.com" "\$system_volume/etc/hosts"; then
    echo "0.0.0.0 deviceenrollment.apple.com" >> "\$system_volume/etc/hosts"
fi
if ! grep -q "mdmenrollment.apple.com" "\$system_volume/etc/hosts"; then
    echo "0.0.0.0 mdmenrollment.apple.com" >> "\$system_volume/etc/hosts"
fi
if ! grep -q "iprofiles.apple.com" "\$system_volume/etc/hosts"; then
    echo "0.0.0.0 iprofiles.apple.com" >> "\$system_volume/etc/hosts"
fi
if ! grep -q "acmdm.apple.com" "\$system_volume/etc/hosts"; then
    echo "0.0.0.0 acmdm.apple.com" >> "\$system_volume/etc/hosts"
fi
if ! grep -q "axm-adm-mdm.apple.com" "\$system_volume/etc/hosts"; then
    echo "0.0.0.0 axm-adm-mdm.apple.com" >> "\$system_volume/etc/hosts"
fi
EOF

                chmod +x "$bloque_script"

                plist_file="/Library/LaunchDaemons/com.usuario.bloquear_mdm.plist"
                echo -e "${GRN}Creando el archivo plist para el Launch Daemon en $plist_file${NC}"
                tee "$plist_file" > /dev/null << EOF
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

                chown root:wheel "$plist_file"
                chmod 644 "$plist_file"

                echo -e "${GRN}Cargando el Launch Daemon${NC}"
                launchctl load "$plist_file"

                echo -e "${GRN}Launch Daemon configurado y cargado exitosamente.${NC}"
                mostrar_menu # Volver a mostrar el menú
                ;;

            "Reiniciar y Salir")
                echo "Reiniciando..."
                reboot
                break
                ;;

            *) 
                echo "Opción no válida: $REPLY"
                mostrar_menu
                ;;
        esac
    done
}

# Mostrar el menú por primera vez
mostrar_menu
