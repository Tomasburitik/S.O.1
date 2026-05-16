#!/bin/bash
# ============================================================
#  SGET - Script Principal (main.sh)
#  Orquesta los módulos del contenedor
# ============================================================

echo "========================================"
echo "  SGET - Módulo de Procesamiento"
echo "  Iniciando sistema..."
echo "========================================"

# Inicializar claves de cifrado
bash /app/scripts/cifrado.sh init

# Iniciar simulación de logging de tráfico en segundo plano
bash /app/scripts/simulador_trafico.sh &
TRAFICO_PID=$!

# Iniciar simulación de amenaza (controlada)
bash /app/scripts/amenaza_simulada.sh &
AMENAZA_PID=$!

echo "[SGET] Módulos activos. PID tráfico=$TRAFICO_PID | PID amenaza=$AMENAZA_PID"
echo "[SGET] Presiona Ctrl+C para detener."

# Esperar señal de terminación
trap "echo '[SGET] Deteniendo módulos...'; kill $TRAFICO_PID $AMENAZA_PID 2>/dev/null; exit 0" SIGTERM SIGINT

wait
