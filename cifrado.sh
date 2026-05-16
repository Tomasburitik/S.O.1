#!/bin/bash
# ============================================================
#  SGET - Módulo de Cifrado (cifrado.sh)
#
#  Implementa políticas de seguridad criptográfica usando
#  OpenSSL (AES-256-CBC). Cifra/descifra archivos clave
#  del contenedor como configuraciones o registros sensibles.
#
#  Uso:
#    bash cifrado.sh init       → Genera clave maestra
#    bash cifrado.sh cifrar     → Cifra el archivo de SD
#    bash cifrado.sh descifrar  → Descifra y muestra contenido
#    bash cifrado.sh verificar  → Verifica integridad con hash
# ============================================================

KEYS_DIR="${SGET_KEYS_DIR:-/app/keys}"
DATA_DIR="${SGET_DATA_DIR:-/app/data}"
VIRTUAL_SD="$DATA_DIR/micro_sd_virtual.txt"
VIRTUAL_SD_ENC="$DATA_DIR/micro_sd_virtual.enc"
CLAVE_MAESTRA="$KEYS_DIR/clave_maestra.key"
HASH_FILE="$KEYS_DIR/integridad.sha256"

ACCION="${1:-ayuda}"

# ── Función: Generar clave maestra ──────────────────────────
generar_clave() {
    echo "[CIFRADO] Generando clave maestra AES-256..."
    openssl rand -base64 32 > "$CLAVE_MAESTRA"
    chmod 600 "$CLAVE_MAESTRA"
    echo "[CIFRADO] Clave guardada en: $CLAVE_MAESTRA"
    echo "[CIFRADO] Permisos restringidos a 600 (solo propietario)."
}

# ── Función: Cifrar archivo ──────────────────────────────────
cifrar_archivo() {
    if [ ! -f "$CLAVE_MAESTRA" ]; then
        echo "[ERROR] Clave maestra no encontrada. Ejecuta 'init' primero."
        exit 1
    fi

    if [ ! -f "$VIRTUAL_SD" ]; then
        echo "[ERROR] Archivo a cifrar no encontrado: $VIRTUAL_SD"
        exit 1
    fi

    echo "[CIFRADO] Cifrando $VIRTUAL_SD con AES-256-CBC..."
    CLAVE=$(cat "$CLAVE_MAESTRA")
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
        -in "$VIRTUAL_SD" \
        -out "$VIRTUAL_SD_ENC" \
        -pass pass:"$CLAVE" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "[CIFRADO] ✓ Archivo cifrado exitosamente: $VIRTUAL_SD_ENC"
        # Generar hash de integridad del archivo cifrado
        sha256sum "$VIRTUAL_SD_ENC" > "$HASH_FILE"
        echo "[CIFRADO] Hash SHA-256 guardado en: $HASH_FILE"
    else
        echo "[ERROR] Falló el cifrado."
        exit 1
    fi
}

# ── Función: Descifrar archivo ──────────────────────────────
descifrar_archivo() {
    if [ ! -f "$VIRTUAL_SD_ENC" ]; then
        echo "[ERROR] Archivo cifrado no encontrado: $VIRTUAL_SD_ENC"
        exit 1
    fi

    CLAVE=$(cat "$CLAVE_MAESTRA")
    echo "[CIFRADO] Descifrando $VIRTUAL_SD_ENC..."
    CONTENIDO=$(openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
        -in "$VIRTUAL_SD_ENC" \
        -pass pass:"$CLAVE" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "[CIFRADO] ✓ Descifrado exitoso. Primeras 10 líneas:"
        echo "──────────────────────────────"
        echo "$CONTENIDO" | head -10
        echo "──────────────────────────────"
    else
        echo "[ERROR] No se pudo descifrar. Clave incorrecta o archivo corrupto."
        exit 1
    fi
}

# ── Función: Verificar integridad ───────────────────────────
verificar_integridad() {
    if [ ! -f "$HASH_FILE" ] || [ ! -f "$VIRTUAL_SD_ENC" ]; then
        echo "[VERIFICACIÓN] Archivos no encontrados para verificar."
        exit 1
    fi

    echo "[VERIFICACIÓN] Comprobando integridad SHA-256..."
    sha256sum -c "$HASH_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[VERIFICACIÓN] ✓ Integridad verificada. El archivo no fue alterado."
    else
        echo "[VERIFICACIÓN] ✗ ALERTA: El archivo fue modificado o está corrupto."
    fi
}

# ── Dispatcher ──────────────────────────────────────────────
case "$ACCION" in
    init)
        generar_clave
        ;;
    cifrar)
        cifrar_archivo
        ;;
    descifrar)
        descifrar_archivo
        ;;
    verificar)
        verificar_integridad
        ;;
    *)
        echo "Uso: bash cifrado.sh [init|cifrar|descifrar|verificar]"
        ;;
esac
