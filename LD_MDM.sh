#!/bin/bash

# Definir códigos de color
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Función para detectar automáticamente la partición del sistema
get_system_volume() {
    # Usar diskutil para listar las particiones montadas y buscar una partición que contenga "Macintosh HD" o similar
    system_volume=$(diskutil list | grep -o '/Volumes/[^ ]*' | head -n 1)
    echo "$system_volume"
}

# Obtener el nombre del volumen del sistema
system_volume=$(get_system_volume)

# Si no se puede detectar, mostrar un mensaje de error
if [ -z "$system_volume" ]; then
    echo -e "${RED}No se pudo detectar el volumen del sistema. Verifique si está montado correctamente.${NC}"
    exit 1
fi

# Mostrar el volumen detectado
echo -e "${GRN}Volumen del sistema detectado: $system_volume${NC}"

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
            if [ -d "$system_volume - Data" ]; then
                diskutil rename "$system_volume - Data" "Data"
            fi

            # Verificar si la ruta de usuarios existe
            dscl_path="$system_volume/private/var/db/dslocal/nodes/Default"
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
            mkdir "$system_volume/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
            dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
            dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username

            # Bloquear dominios MDM en /etc/hosts
            echo "Bloqueando dominios MDM en /etc/hosts..."
            sudo sed -i '' '/# MDM Servers/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/# End/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/deviceenrollment.apple.com/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/mdmenrollment.apple.com/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/iprofiles.apple.com/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/acmdm.apple.com/d' "$system_volume/etc/hosts"
            sudo sed -i '' '/axm-adm-mdm.apple.com/d' "$system_volume/etc/hosts"

            echo "# MDM Servers" | sudo tee -a "$system_volume/etc/hosts"
            echo "0.0.0.0 deviceenrollment.apple.com" | sudo tee -a "$system_volume/etc/hosts"
            echo "0.0.0.0 mdmenrollment.apple.com" | sudo tee -a "$system_volume/etc/hosts"
            echo "0.0.0.0 iprofiles.apple.com" | sudo tee -a "$system_volume/etc/hosts"
            echo "0.0.0.0 acmdm.apple.com" | sudo tee -a "$system_volume/etc/hosts"
            echo "0.0.0.0 axm-adm-mdm.apple.com" | sudo tee -a "$system_volume/etc/hosts"
            echo "# End" | sudo tee -a "$system_volume/etc/hosts"
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
            sudo rm /var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord
            sudo rm /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound
            sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled
            sudo touch /var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound
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
            sudo profiles show -type enrollment
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

