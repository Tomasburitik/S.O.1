#!/bin/bash
# ============================================================
#  SGET - Simulación de Amenaza Controlada (amenaza_simulada.sh)
#
#  PROPÓSITO EDUCATIVO: Este script simula el comportamiento
#  de un proceso malicioso (virus tipo "backdoor silencioso")
#  dentro del contenedor SGET, de forma completamente segura
#  y predecible, sin causar daño real al sistema.
#
#  Tipo de amenaza simulada: INFILTRACIÓN / INTERCEPCIÓN
#  El proceso finge intentar acceder a archivos restringidos
#  y modificar configuraciones del sistema, pero todas las
#  acciones son bloqueadas o redirigidas de forma segura.
#
#  El SGET detecta este comportamiento y lo registra.
# ============================================================

LOG_DIR="${SGET_LOG_DIR:-/app/logs}"
AMENAZA_LOG="$LOG_DIR/amenaza_detectada.log"

log_amenaza() {
    local nivel="$1"
    local mensaje="$2"
    echo "[$nivel][$(date '+%H:%M:%S')] $mensaje" | tee -a "$AMENAZA_LOG"
}

log_sget() {
    local mensaje="$1"
    echo "[SGET-DEFENSA][$(date '+%H:%M:%S')] $mensaje" | tee -a "$LOG_DIR/defensa.log"
}

# ── Banner ───────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  [SIMULACIÓN] Módulo de Amenaza Activo"
echo "  Tipo: Infiltración / Intercepción"
echo "  NOTA: Solo fines educativos. No daña."
echo "========================================"

sleep 3

# ── Fase 1: Reconocimiento (el proceso malicioso "explora") ──
log_amenaza "AMENAZA" "Iniciando reconocimiento del sistema..."
log_amenaza "AMENAZA" "Intentando leer /etc/passwd..."

# Intento fallido (usuario sin privilegios no puede escribir en /etc)
if cat /etc/passwd 2>/dev/null | grep -q root; then
    log_amenaza "AMENAZA" "Lectura parcial de /etc/passwd exitosa (datos de sistema visibles)"
else
    log_amenaza "AMENAZA" "Acceso a /etc/passwd bloqueado."
fi

log_sget "Actividad inusual detectada: lectura de /etc/passwd por proceso no autorizado."

sleep 4

# ── Fase 2: Intento de escalada de privilegios ──────────────
log_amenaza "AMENAZA" "Intentando ejecutar 'sudo su'..."
# sudo no está disponible ni configurado → falla de forma segura
sudo su 2>/dev/null && log_amenaza "AMENAZA" "Escalada exitosa (ESTO NO DEBERÍA OCURRIR)" || \
    log_amenaza "AMENAZA" "Escalada de privilegios BLOQUEADA: sudo no disponible."

log_sget "Intento de escalada de privilegios bloqueado. Usuario: sget_user sin permisos sudo."

sleep 4

# ── Fase 3: Intento de modificar archivos del sistema ────────
log_amenaza "AMENAZA" "Intentando escribir en /etc/crontab..."
echo "* * * * * malware" >> /etc/crontab 2>/dev/null && \
    log_amenaza "AMENAZA" "Escritura en crontab exitosa (PELIGRO)" || \
    log_amenaza "AMENAZA" "Escritura en /etc/crontab BLOQUEADA: permisos insuficientes."

log_sget "Intento de modificar /etc/crontab bloqueado por políticas de usuario sin privilegios."

sleep 4

# ── Fase 4: Intento de exfiltración de datos ────────────────
log_amenaza "AMENAZA" "Intentando copiar archivo de claves..."
KEYS_DIR="${SGET_KEYS_DIR:-/app/keys}"

# Intentar leer la clave maestra (directorio con permisos 700)
cat "$KEYS_DIR/clave_maestra.key" 2>/dev/null && \
    log_amenaza "AMENAZA" "Clave maestra leída (ALERTA CRÍTICA)" || \
    log_amenaza "AMENAZA" "Acceso a clave maestra DENEGADO: directorio /app/keys con permisos 700."

log_sget "Intento de exfiltración de clave maestra bloqueado. Directorio protegido con chmod 700."

sleep 4

# ── Fase 5: Detección y mitigación por el SGET ──────────────
echo ""
log_sget "=========================================="
log_sget "RESUMEN DE DETECCIÓN DE AMENAZA:"
log_sget "Tipo detectado: Infiltración / Intercepción"
log_sget "Acciones bloqueadas: 4 (reconocimiento, escalada, modificación, exfiltración)"
log_sget "El contenedor detuvo TODAS las acciones maliciosas."
log_sget "Medidas de protección aplicadas:"
log_sget "  1. Usuario sget_user sin sudo"
log_sget "  2. /app/keys con permisos 700"
log_sget "  3. Root deshabilitado (passwd -l root)"
log_sget "  4. Alpine minimal: sin herramientas de red avanzadas"
log_sget "=========================================="

echo ""
echo "[SIMULACIÓN] Amenaza neutralizada. Ver log: $AMENAZA_LOG"

# La amenaza "duerme" (proceso terminado con éxito controlado)
exit 0
