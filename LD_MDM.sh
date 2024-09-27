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

# Mostrar el menú con opciones
PS3='Por favor, elige una opción: '
options=("Bypass MDM desde Recovery" "Deshabilitar Notificaciones (SIP)" "Deshabilitar Notificaciones (Recovery)" "Verificar inscripción en MDM" "Configurar Launch Daemon para Bloqueo Permanente" "Reiniciar y Salir")
select opt in "${options[@]}"; do
    case $opt in
        "Bypass MDM desde Recovery")
            echo -e "${YEL}Bypass MDM desde Recovery${NC}"
            # Usar /Volumes/macOS Base System en lugar de /Volumes/Macintosh HD
            system_volume="/Volumes/macOS Base System"

            # Verificar si la partición de datos está montada
            if [ -d "$system_volume - Data" ]; then
                diskutil rename "$system_volume - Data" "Data"
            fi

            # Bloquear dominios MDM en /etc/hosts
            echo "Bloqueando dominios MDM en /etc/hosts..."
            sed -i '' '/# MDM Servers/d' "$system_volume/etc/hosts"
            sed -i '' '/# End/d' "$system_volume/etc/hosts"
            sed -i '' '/deviceenrollment.apple.com/d' "$system_volume/etc/hosts"
            sed -i '' '/mdmenrollment.apple.com/d' "$system_volume/etc/hosts"
            sed -i '' '/iprofiles.apple.com/d' "$system_volume/etc/hosts"
            sed -i '' '/acmdm.apple.com/d' "$system_volume/etc/hosts"
            sed -i '' '/axm-adm-mdm.apple.com/d' "$system_volume/etc/hosts"

            echo "# MDM Servers" >> "$system_volume/etc/hosts"
            echo "0.0.0.0 deviceenrollment.apple.com" >> "$system_volume/etc/hosts"
            echo "0.0.0.0 mdmenrollment.apple.com" >> "$system_volume/etc/hosts"
            echo "0.0.0.0 iprofiles.apple.com" >> "$system_volume/etc/hosts"
            echo "0.0.0.0 acmdm.apple.com" >> "$system_volume/etc/hosts"
            echo "0.0.0.0 axm-adm-mdm.apple.com" >> "$system_volume/etc/hosts"
            echo "# End" >> "$system_volume/etc/hosts"
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
            break
            ;;

        "Deshabilitar Notificaciones (SIP)")
            # Deshabilitar notificaciones (SIP)
            echo -e "${RED}Introduce tu contraseña para proceder${NC}"
            rm /var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
            rm /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
            touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
            touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
            echo -e "${GRN}Notificaciones deshabilitadas exitosamente (SIP)${NC}"
            break
            ;;

        "Deshabilitar Notificaciones (Recovery)")
            # Deshabilitar notificaciones desde Recovery
            rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
            rm -rf "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
            touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
            touch "$system_volume/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"
            echo -e "${GRN}Notificaciones deshabilitadas exitosamente desde Recovery${NC}"
            break
            ;;

        "Verificar inscripción en MDM")
            # Verificar la inscripción en MDM
            echo -e "${GRN}Verificación de inscripción en MDM${NC}"
            profiles show -type enrollment
            break
            ;;

        "Configurar Launch Daemon para Bloqueo Permanente")
            # Configurar Launch Daemon (el bloque de código aquí es el mismo de antes)
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

