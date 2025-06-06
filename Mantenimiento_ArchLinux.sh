#!/bin/bash

#==== Configuración de colores ====
rojo="\e[31m"; verde="\e[32m"; amarillo="\e[33m"; azul="\e[34m"
magenta="\e[35m"; cian="\e[36m"; blanco="\e[97m"; negrita="\e[1m"
reset="\e[0m"

#==== Variables ====
LOG_FILE=~/mantenimiento_$(date +%Y-%m-%d_%H-%M-%S).log
VERSION="2.0"
SISTEMA=$(uname -n)

#==== Funciones ====
header() {
    clear
    echo -e "${azul}${negrita}"
    echo "══════════════════════════════════════════════════"
    echo "   SISTEMA DE MANTENIMIENTO PARA ARCH LINUX"
    echo "   Versión ${VERSION} - Host: ${SISTEMA}"
    echo "══════════════════════════════════════════════════${reset}"
    echo -e "${cian}Registro detallado: ${blanco}${LOG_FILE}${reset}"
    echo -e "${cian}Tiempo de inicio: ${blanco}$(date)${reset}\n"
}

ejecutar() {
    local mensaje="$1"; local comando="$2"; local reparar="$3"
    echo -e "\n${azul}▶ ${blanco}${mensaje}...${reset}"
    echo -e "Comando: ${comando}\n" >> "$LOG_FILE"

    if eval "${comando}" >> "$LOG_FILE" 2>&1; then
        echo -e "${verde}  ✔ Operación completada con éxito${reset}"
    else
        echo -e "${rojo}  ✖ Error en la operación (Código $?)${reset}"
        if [ -n "$reparar" ]; then
            echo -e "${amarillo}  ⟳ Intentando reparar...${reset}"
            if eval "$reparar" >> "$LOG_FILE" 2>&1; then
                echo -e "${verde}  ✔ Reparación exitosa${reset}"
            else
                echo -e "${rojo}  ✖ Error en la reparación${reset}"
            fi
        fi
    fi
}

limpieza_basica() {
    echo -e "${magenta}${negrita}[ FASE 1 ] LIMPIEZA DEL SISTEMA${reset}"
    ejecutar "Limpiando logs del journal (mayores a 3 días)" "sudo journalctl --vacuum-time=3d"
    if pacman -Qtdq >/dev/null 2>&1; then
        ejecutar "Eliminando paquetes huérfanos" "sudo pacman -Rns \$(pacman -Qtdq) --noconfirm"
    else
        echo -e "${amarillo}  No hay paquetes huérfanos para eliminar.${reset}"
    fi
    ejecutar "Limpiando caché de paquetes" "sudo pacman -Scc --noconfirm"
    ejecutar "Limpiando caché de usuario" "rm -rf ~/.cache/* ~/.thumbnails/*"
    [ -d /tmp ] && ejecutar "Limpiando archivos temporales" "sudo rm -rf /tmp/*"
    [ -d /var/tmp ] && ejecutar "Limpiando archivos temporales" "sudo rm -rf /var/tmp/*"
}

optimizacion_sistema() {
    echo -e "${magenta}${negrita}[ FASE 2 ] OPTIMIZACIÓN DEL SISTEMA${reset}"
    ejecutar "Liberando caché de memoria" "sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches"
    ejecutar "Actualizando el sistema (pacman)" "sudo pacman -Syu --noconfirm"
    if command -v yay >/dev/null; then
        ejecutar "Actualizando AUR (yay)" "yay -Sua --noconfirm"
    fi
    if command -v paccache >/dev/null; then
        ejecutar "Limpiando versiones antiguas" "paccache -rk1"
    else
        echo -e "${amarillo}  'paccache' no está instalado.${reset}"
    fi
    ejecutar "Verificando archivos corruptos" "sudo pacman -Qkkq" "sudo pacman -S --noconfirm \$(pacman -Qkkq | awk '{print \$1}')"
}

verificacion_sistema() {
    echo -e "${magenta}${negrita}[ FASE 3 ] VERIFICACIÓN DEL SISTEMA${reset}"
    ejecutar "Comprobando espacio en disco" "df -h"
    ejecutar "Comprobando uso de memoria" "free -h"
    ejecutar "Contando paquetes instalados" "pacman -Q | wc -l"
    ejecutar "Verificando servicios fallidos" "systemctl --failed"
}

resumen_final() {
    echo -e "${verde}${negrita}\n══════════════════════════════════════════════════${reset}"
    echo -e "${blanco}${negrita}            INFORME FINAL DE MANTENIMIENTO            ${reset}"
    echo -e "${verde}${negrita}══════════════════════════════════════════════════${reset}"
    echo -e "${cian}► RESUMEN ESTADÍSTICO:${reset}"
    uso_disco=$(df -h / | tail -1 | awk '{print $3 " usados de " $2 " (" $5 ")"}')
    mem_libre=$(free -h | awk '/Mem/ {print $4 " libres de " $2}')
    paquetes=$(pacman -Q | wc -l)
    echo -e "${blanco}  - Espacio en disco:    ${uso_disco}${reset}"
    echo -e "${blanco}  - Memoria libre:       ${mem_libre}${reset}"
    echo -e "${blanco}  - Paquetes instalados: ${paquetes}${reset}"
    echo -e "${verde}${negrita}\n══════════════════════════════════════════════════${reset}"
    echo -e "${blanco}${negrita}✅ MANTENIMIENTO COMPLETADO ✅${reset}"
    echo -e "${verde}${negrita}══════════════════════════════════════════════════${reset}"
    echo -e "${amarillo}Registro guardado en: ${blanco}${LOG_FILE}${reset}"
    echo -e "${cian}Finalización: ${blanco}$(date)${reset}"
    echo -e "${magenta}${negrita}[✔] Sistema optimizado y listo para usar [✔]${reset}"
}

mostrar_menu() {
    header
    echo -e "${blanco}${negrita}Selecciona una acción:${reset}"
    options=("Limpieza" "Optimización" "Verificación" "Todo el mantenimiento" "Salir")
    select opt in "${options[@]}"; do
        case $REPLY in
            1) limpieza_basica; break ;;
            2) optimizacion_sistema; break ;;
            3) verificacion_sistema; break ;;
            4) limpieza_basica; optimizacion_sistema; verificacion_sistema; resumen_final; break ;;
            5) echo -e "${amarillo}Saliendo...${reset}"; exit 0 ;;
            *) echo -e "${rojo}Opción inválida. Intenta de nuevo.${reset}" ;;
        esac
    done
}

#==== Ejecución ====
mostrar_menu
