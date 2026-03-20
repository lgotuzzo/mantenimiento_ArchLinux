#!/bin/bash

#===========================================
# SISTEMA DE MANTENIMIENTO AVANZADO PARA ARCH LINUX
# Versión 3.0 - Con soporte para Secure Boot Dual Boot
#===========================================

#==== Configuración de colores ====
rojo="\e[31m"; verde="\e[32m"; amarillo="\e[33m"; azul="\e[34m"
magenta="\e[35m"; cian="\e[36m"; blanco="\e[97m"; negrita="\e[1m"
reset="\e[0m"

#==== Variables ====
LOG_FILE=~/mantenimiento_$(date +%Y-%m-%d_%H-%M-%S).log
VERSION="3.0"
SISTEMA=$(uname -n)
MODO_SILENCIOSO=false

#==== Funciones de utilidad ====
header() {
    clear
    echo -e "${azul}${negrita}"
    echo "══════════════════════════════════════════════════════════════"
    echo "   SISTEMA DE MANTENIMIENTO AVANZADO PARA ARCH LINUX"
    echo "   Versión ${VERSION} - Host: ${SISTEMA}"
    echo "══════════════════════════════════════════════════════════════${reset}"
    echo -e "${cian}Registro detallado: ${blanco}${LOG_FILE}${reset}"
    echo -e "${cian}Tiempo de inicio: ${blanco}$(date)${reset}\n"
}

ejecutar() {
    local mensaje="$1"
    local comando="$2"
    local reparar="$3"

    echo -e "\n${azul}▶ ${blanco}${mensaje}...${reset}"
    echo -e "Comando: ${comando}\n" >> "$LOG_FILE"

    if eval "${comando}" >> "$LOG_FILE" 2>&1; then
        echo -e "${verde}  ✔ Operación completada con éxito${reset}"
        return 0
    else
        local exit_code=$?
        echo -e "${rojo}  ✖ Error en la operación (Código ${exit_code})${reset}"

        if [ -n "$reparar" ]; then
            echo -e "${amarillo}  ⟳ Intentando reparar...${reset}"
            if eval "$reparar" >> "$LOG_FILE" 2>&1; then
                echo -e "${verde}  ✔ Reparación exitosa${reset}"
                return 0
            else
                echo -e "${rojo}  ✖ Error en la reparación${reset}"
                return 1
            fi
        fi
        return ${exit_code}
    fi
}

notificar() {
    if [ "$MODO_SILENCIOSO" = false ] && command -v notify-send >/dev/null; then
        notify-send -t 5000 -u normal "$1" "$2"
    fi
}

#==== FASE 0: BACKUP PREVENTIVO ====
backup_previo() {
    echo -e "${magenta}${negrita}[ FASE 0 ] BACKUP PREVENTIVO${reset}"

    # Crear directorio de backups si no existe
    mkdir -p ~/.config/backups 2>/dev/null

    # Backup de lista de paquetes
    ejecutar "Backup de lista de paquetes oficiales" \
        "pacman -Qqe > ~/.config/backups/pacman_installed_$(date +%Y-%m-%d).txt"

    # Backup de lista de paquetes AUR (si yay existe)
    if command -v yay >/dev/null; then
        ejecutar "Backup de lista de paquetes AUR" \
            "pacman -Qqm > ~/.config/backups/aur_installed_$(date +%Y-%m-%d).txt"
    fi

    # Backup de keyring de pacman
    ejecutar "Backup de keyring de pacman" \
        "sudo pacman-key --export > ~/.config/backups/pacman-key_backup_$(date +%Y-%m-%d).asc"

    # Mantener solo los últimos 5 backups
    cd ~/.config/backups && ls -t pacman_installed_*.txt 2>/dev/null | tail -n +6 | xargs -r rm
    cd ~/.config/backups && ls -t pacman-key_backup_*.asc 2>/dev/null | tail -n +6 | xargs -r rm

    echo -e "${verde}  ✔ Backups completados en ~/.config/backups/${reset}"
}

#==== FASE 1: LIMPIEZA BÁSICA ====
limpieza_basica() {
    echo -e "${magenta}${negrita}[ FASE 1 ] LIMPIEZA DEL SISTEMA${reset}"

    # Limpiar logs del journal
    ejecutar "Limpiando logs del journal (mayores a 3 días)" \
        "sudo journalctl --vacuum-time=3d"

    # Limpiar paquetes huérfanos
    if pacman -Qtdq >/dev/null 2>&1; then
        ejecutar "Eliminando paquetes huérfanos" \
            "sudo pacman -Rns \$(pacman -Qtdq) --noconfirm"
    else
        echo -e "${amarillo}  No hay paquetes huérfanos para eliminar.${reset}"
    fi

    # Limpiar caché de paquetes
    ejecutar "Limpiando caché de paquetes" \
        "sudo pacman -Scc --noconfirm"

    # Limpiar caché de usuario (solo archivos temporales seguros)
    ejecutar "Limpiando caché de usuario" \
        "rm -rf ~/.cache/*/thumbnails ~/.cache/*/cache ~/.thumbnails 2>/dev/null"

    # Limpiar archivos temporales
    [ -d /tmp ] && ejecutar "Limpiando /tmp" "sudo rm -rf /tmp/*"
    [ -d /var/tmp ] && ejecutar "Limpiando /var/tmp" "sudo rm -rf /var/tmp/*"
}

#==== FASE 1B: LIMPIEZA PROFUNDA ====
limpieza_profunda() {
    echo -e "${magenta}${negrita}[ FASE 1B ] LIMPIEZA PROFUNDA${reset}"

    # Limpiar core dumps
    ejecutar "Limpiando core dumps" \
        "sudo rm -f /var/lib/systemd/coredump/* 2>/dev/null"

    # Limpiar Steam
    if [ -d ~/.steam ]; then
        ejecutar "Limpiando logs de Steam" \
            "find ~/.steam -name '*.log' -delete 2>/dev/null"
    fi

    # Limpiar navegadores
    ejecutar "Limpiando caché de navegadores" "
        rm -rf ~/.cache/google-chrome/* 2>/dev/null
        rm -rf ~/.cache/chromium/* 2>/dev/null
        rm -rf ~/.cache/mozilla/firefox/*/cache2 2>/dev/null
        rm -rf ~/.cache/BraveSoftware/*/Default/Cache/* 2>/dev/null
    "

    # Limpiar paquetes huérfanos de AUR
    if command -v yay >/dev/null; then
        ejecutar "Limpiando huérfanos de AUR" \
            "yay -Yc --noconfirm"
    fi

    # Limpiar archivos de basura de desarrolladores
    ejecutar "Limpiando archivos temporales de desarrollo" "
        find ~ -type d -name 'node_modules' -exec rm -rf {} + 2>/dev/null
        find ~ -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null
        find ~ -type f -name '*.pyc' -delete 2>/dev/null
        find ~ -type f -name '*.class' -delete 2>/dev/null
    " "true"
}

#==== FASE 2: ACTUALIZACIÓN Y OPTIMIZACIÓN ====
optimizacion_sistema() {
    echo -e "${magenta}${negrita}[ FASE 2 ] OPTIMIZACIÓN DEL SISTEMA${reset}"

    # Liberar caché de memoria
    ejecutar "Liberando caché de memoria" \
        "sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null"

    # Actualizar repositorios
    ejecutar "Actualizando repositorios" \
        "sudo pacman -Sy --noconfirm"

    # Actualizar el sistema
    ejecutar "Actualizando el sistema (pacman)" \
        "sudo pacman -Su --noconfirm"

    # Actualizar AUR
    if command -v yay >/dev/null; then
        ejecutar "Actualizando AUR (yay)" \
            "yay -Sua --noconfirm"
    fi

    # Limpiar versiones antiguas de paquetes
    if command -v paccache >/dev/null; then
        ejecutar "Limpiando versiones antiguas de paquetes" \
            "paccache -rk2"
    fi

    # Verificar archivos corruptos y reparar
    ejecutar "Verificando archivos corruptos" \
        "sudo pacman -Qkkq" \
        "sudo pacman -S --noconfirm \$(sudo pacman -Qkkq | awk '{print \$1}' | sort -u)"

    # Firmar archivos para Secure Boot (dual boot)
    if command -v sbctl >/dev/null; then
        ejecutar "Firmando archivos para Secure Boot" \
            "sudo sbctl sign-all"
    fi

    # Actualizar GRUB si existe
    if [ -d /boot/grub ]; then
        ejecutar "Actualizando configuración de GRUB" \
            "sudo grub-mkconfig -o /boot/grub/grub.cfg"
    fi
}

#==== FASE 3: VERIFICACIÓN DEL SISTEMA ====
verificacion_sistema() {
    echo -e "${magenta}${negrita}[ FASE 3 ] VERIFICACIÓN DEL SISTEMA${reset}"

    ejecutar "Comprobando espacio en disco" "df -h"
    ejecutar "Comprobando uso de memoria" "free -h"
    ejecutar "Contando paquetes instalados" "pacman -Q | wc -l"
    ejecutar "Verificando servicios fallidos" "systemctl --failed --no-pager"
    ejecutar "Verificando servicios habilitados" "systemctl list-unit-files --state=enabled --no-pager | head -20"
}

#==== FASE 3B: VERIFICACIÓN DE INTEGRIDAD ====
verificacion_integridad() {
    echo -e "${magenta}${negrita}[ FASE 3B ] VERIFICACIÓN DE INTEGRIDAD${reset}"

    # Verificar integridad de paquetes base
    ejecutar "Verificando paquetes base" \
        "pacman -Qkk base base-devel linux linux-firmware 2>&1 | grep -v 'missing' || true"

    # Verificar Secure Boot
    if command -v sbctl >/dev/null; then
        ejecutar "Verificando estado de Secure Boot" \
            "sbctl status"
    fi

    # Verificar integridad de paquetes dañados
    local corrupted=$(sudo pacman -Qkk 2>&1 | grep -c "corrupted")
    if [ "$corrupted" -gt 0 ]; then
        echo -e "${amarillo}  ⚠ Se encontraron ${corrupted} paquetes corruptos${reset}"
        ejecutar "Reparando paquetes corruptos" \
            "sudo pacman -S --noconfirm \$(sudo pacman -Qkk 2>&1 | grep 'corrupted' | awk '{print \$2}' | sort -u)"
    fi

    # Verificar permisos de directorios importantes
    echo -e "\n${cian}  Verificando permisos críticos...${reset}"
    for dir in /boot /etc /var; do
        if [ -d "$dir" ]; then
            echo -e "    - $dir: $(ls -ld $dir | awk '{print $1, $3, $4}')"
        fi
    done >> "$LOG_FILE"
}

#==== RESUMEN FINAL ====
resumen_final() {
    echo -e "${verde}${negrita}\n══════════════════════════════════════════════════════════════${reset}"
    echo -e "${blanco}${negrita}            INFORME FINAL DE MANTENIMIENTO            ${reset}"
    echo -e "${verde}${negrita}══════════════════════════════════════════════════════════════${reset}"

    # Estadísticas
    uso_disco=$(df -h / | tail -1 | awk '{print $3 " usados de " $2 " (" $5 ")"}')
    mem_libre=$(free -h | awk '/Mem/ {print $4 " libres de " $2}')
    paquetes=$(pacman -Q | wc -l)
    paquetes_aur=$(pacman -Qm 2>/dev/null | wc -l)

    echo -e "${cian}► RESUMEN ESTADÍSTICO:${reset}"
    echo -e "${blanco}  - Espacio en disco:    ${uso_disco}${reset}"
    echo -e "${blanco}  - Memoria libre:       ${mem_libre}${reset}"
    echo -e "${blanco}  - Paquetes oficiales:  ${paquetes}${reset}"
    echo -e "${blanco}  - Paquetes AUR:        ${paquetes_aur}${reset}"

    # Estado de Secure Boot
    if command -v sbctl >/dev/null; then
        sb_status=$(sbctl status | grep -i "Setup Mode" || echo "No detectado")
        echo -e "${blanco}  - Secure Boot:         ${sb_status}${reset}"
    fi

    echo -e "${verde}${negrita}\n══════════════════════════════════════════════════════════════${reset}"
    echo -e "${blanco}${negrita}✅ MANTENIMIENTO COMPLETADO ✅${reset}"
    echo -e "${verde}${negrita}══════════════════════════════════════════════════════════════${reset}"
    echo -e "${amarillo}Registro guardado en: ${blanco}${LOG_FILE}${reset}"
    echo -e "${cian}Finalización: ${blanco}$(date)${reset}"
    echo -e "${magenta}${negrita}[✔] Sistema optimizado y listo para usar [✔]${reset}"

    notificar "Mantenimiento completado" "El sistema ha sido optimizado correctamente"
}

#==== MENÚ PRINCIPAL ====
mostrar_menu() {
    header
    echo -e "${blanco}${negrita}Selecciona una acción:${reset}"
    echo -e "${cian}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    options=(
        "Limpieza básica"
        "Limpieza profunda"
        "Actualización y optimización (con Secure Boot)"
        "Verificación del sistema"
        "Verificación de integridad"
        "Backup preventivo"
        "TODO el mantenimiento (RECOMENDADO)"
        "Salir"
    )

    PS3="$(echo -e ${blanco}Opción \(1-8\): ${reset})"
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                limpieza_basica
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            2)
                limpieza_profunda
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            3)
                optimizacion_sistema
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            4)
                verificacion_sistema
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            5)
                verificacion_integridad
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            6)
                backup_previo
                echo -e "\n${verde}Presiona Enter para continuar...${reset}"
                read
                mostrar_menu
                break
                ;;
            7)
                header
                echo -e "${amarillo}Iniciando mantenimiento completo...${reset}\n"
                backup_previo
                limpieza_basica
                limpieza_profunda
                optimizacion_sistema
                verificacion_sistema
                verificacion_integridad
                resumen_final
                echo -e "\n${verde}Presiona Enter para salir...${reset}"
                read
                exit 0
                ;;
            8)
                echo -e "${amarillo}Saliendo...${reset}"
                exit 0
                ;;
            *)
                echo -e "${rojo}Opción inválida. Intenta de nuevo.${reset}"
                ;;
        esac
    done
}

#==== EJECUCIÓN ====
# Verificar si se ejecuta con --silent para modo automático
if [[ "$1" == "--silent" ]] || [[ "$1" == "-s" ]]; then
    MODO_SILENCIOSO=true
    backup_previo
    limpieza_basica
    limpieza_profunda
    optimizacion_sistema
    verificacion_sistema
    verificacion_integridad
    resumen_final
else
    mostrar_menu
fi
