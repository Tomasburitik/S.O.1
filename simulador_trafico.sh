#!/bin/bash
# ============================================================
#  SGET - Simulador de Logging de Tráfico (simulador_trafico.sh)
#
#  Simula el comportamiento de un módulo Micro-SD con tres
#  "tareas" al estilo FreeRTOS:
#    - Tarea 1: Leer datos del sensor (vTaskDelay equivalente)
#    - Tarea 2: Escribir en la Micro-SD virtual
#    - Tarea 3: Cerrar y verificar integridad del archivo
#
#  Equivalencias de funciones Arduino/FreeRTOS:
#    SD.open()   → función sd_open()
#    SD.write()  → función sd_write()
#    SD.close()  → función sd_close()
#    file.seek() → función sd_seek()
# ============================================================

LOG_DIR="${SGET_LOG_DIR:-/app/logs}"
DATA_DIR="${SGET_DATA_DIR:-/app/data}"
VIRTUAL_SD="$DATA_DIR/micro_sd_virtual.txt"
INTERVAL="${SGET_INTERVAL:-5}"

# ── Funciones que simulan la API de Micro-SD ────────────────

sd_open() {
    local filename="$1"
    local mode="$2"   # r=lectura, w=escritura, a=append
    echo "[SD.open] Abriendo archivo: $filename | Modo: $mode"
    # Simula el handle de archivo
    echo "$filename"
}

sd_write() {
    local filepath="$1"
    local data="$2"
    echo "$data" >> "$filepath"
    echo "[SD.write] Escrito en $filepath: $data"
}

sd_close() {
    local filepath="$1"
    sync  # Forzar escritura a disco (equivalente a cerrar handle)
    echo "[SD.close] Archivo cerrado y sincronizado: $filepath"
}

sd_seek() {
    local filepath="$1"
    local position="$2"
    # Simula file.seek() leyendo desde cierta posición
    local content
    content=$(tail -n +"$position" "$filepath" 2>/dev/null)
    echo "[SD.seek] Buscando posición $position en $filepath"
    echo "$content" | head -5
}

# ── Tarea 1: Leer sensor de tráfico (simula vTaskDelay) ─────
tarea_leer_sensor() {
    local vehiculos=$((RANDOM % 200 + 10))
    local velocidad=$((RANDOM % 120 + 20))
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "SENSOR|$timestamp|vehiculos=$vehiculos|velocidad_promedio=${velocidad}km/h"
}

# ── Tarea 2: Escribir datos en la Micro-SD virtual ──────────
tarea_escribir_sd() {
    local dato="$1"
    sd_open "$VIRTUAL_SD" "a" > /dev/null
    sd_write "$VIRTUAL_SD" "$dato"
    sd_close "$VIRTUAL_SD"
}

# ── Tarea 3: Verificar integridad leyendo con seek ──────────
tarea_verificar() {
    local total_lineas
    total_lineas=$(wc -l < "$VIRTUAL_SD" 2>/dev/null || echo 0)
    if [ "$total_lineas" -gt 5 ]; then
        echo "[Verificación] Últimos registros en Micro-SD:"
        sd_seek "$VIRTUAL_SD" "$((total_lineas - 4))"
    fi
}

# ── Inicialización ──────────────────────────────────────────
echo "[SGET-TRAFICO] Iniciando simulador de tráfico..."
echo "[SGET-TRAFICO] Micro-SD virtual en: $VIRTUAL_SD"

# Crear encabezado del archivo SD si no existe
if [ ! -f "$VIRTUAL_SD" ]; then
    sd_open "$VIRTUAL_SD" "w" > /dev/null
    sd_write "$VIRTUAL_SD" "# SGET - Registro de tráfico | Inicio: $(date)"
    sd_write "$VIRTUAL_SD" "# Formato: SENSOR|timestamp|vehiculos|velocidad_promedio"
    sd_close "$VIRTUAL_SD"
fi

# ── Bucle principal (simula scheduler de FreeRTOS) ──────────
CICLO=0
while true; do
    CICLO=$((CICLO + 1))
    echo ""
    echo "--- [Ciclo FreeRTOS #$CICLO] ---"

    # Tarea 1: Leer sensor
    DATO=$(tarea_leer_sensor)
    echo "[Tarea-Leer] $DATO"

    # Tarea 2: Escribir en SD
    tarea_escribir_sd "$DATO"

    # Cada 3 ciclos, verificar integridad (Tarea 3)
    if [ $((CICLO % 3)) -eq 0 ]; then
        tarea_verificar
    fi

    # Log en archivo de auditoría
    echo "[$(date '+%H:%M:%S')] Ciclo $CICLO completado." >> "$LOG_DIR/auditoria.log"

    # vTaskDelay equivalente
    sleep "$INTERVAL"
done
