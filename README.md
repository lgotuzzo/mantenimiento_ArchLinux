# Mantenimiento_Archlinux.sh

Este script Bash automatiza tareas de mantenimiento en sistemas Arch Linux y derivados. Proporciona una interfaz interactiva, es modular y cuenta con soporte para paquetes AUR utilizando `yay`.

## Características

- Limpieza de logs, cachés de usuario y paquetes huérfanos
- Eliminación de archivos temporales
- Actualización del sistema (`pacman` y AUR)
- Liberación de caché de memoria
- Verificación de integridad de paquetes
- Estadísticas del sistema (uso de disco, memoria, cantidad de paquetes)
- Menú interactivo para seleccionar tareas
- Registro detallado por ejecución

## Requisitos

- Arch Linux o derivado
- `bash`
- `yay` (para soporte AUR)
- Permisos de `sudo`

## Instalación

Clona el repositorio y otorga permisos de ejecución:

```bash
git clone https://github.com/tu_usuario/Mantenimiento_Archlinux.sh.git
cd Mantenimiento_Archlinux.sh
chmod +x Mantenimiento_Archlinux.sh

##  Ejecutar 
./Mantenimiento_Archlinux.sh
