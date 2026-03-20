
## README.md (actualizado)

```markdown
# Mantenimiento_Archlinux.sh v2.0

Script Bash que automatiza tareas de mantenimiento en sistemas Arch Linux y derivados, ahora con soporte para Secure Boot y dual boot.

## ✨ Características

### Limpieza
- Logs del journal (mayores a 3 días)
- Paquetes huérfanos (oficiales y AUR)
- Caché de paquetes y usuario
- Archivos temporales (/tmp, /var/tmp)
- **NUEVO**: Core dumps y logs de Steam
- **NUEVO**: Caché de navegadores (Chrome, Firefox, Brave)

### Optimización
- Liberación de caché de memoria
- Actualización del sistema (pacman y AUR)
- Limpieza de versiones antiguas de paquetes
- **NUEVO**: Firmado de archivos para Secure Boot (sbctl)
- **NUEVO**: Actualización automática de GRUB

### Verificación
- Integridad de paquetes con reparación automática
- Espacio en disco y uso de memoria
- Servicios fallidos del sistema
- **NUEVO**: Estado de Secure Boot

### Backups
- **NUEVO**: Backup automático de listas de paquetes
- **NUEVO**: Mantenimiento de últimos 5 backups
- **NUEVO**: Modo silencioso para ejecución automática

## 📋 Requisitos

- Arch Linux o derivado
- Bash
- yay (para soporte AUR)
- Permisos de sudo
- **Opcional**: sbctl (para Secure Boot)
- **Opcional**: pacman-contrib (para paccache)

## 🚀 Instalación

```bash
git clone https://github.com/lgotuzzo/Mantenimiento_Archlinux.sh.git
cd Mantenimiento_Archlinux.sh
chmod +x Mantenimiento_ArchLinux.sh
