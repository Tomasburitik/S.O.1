# ============================================================
#  SGET - Sistema Inteligente de Gestión de Tráfico
#  Módulo: Procesamiento de datos en tiempo real
#  Base: Alpine Linux (ligera, segura, ideal para contenedores)
# ============================================================

FROM alpine:3.19

# Metadatos del contenedor
LABEL maintainer="Estudiante SGET"
LABEL description="Contenedor personalizado para módulo SGET - Procesamiento de tráfico en tiempo real"
LABEL version="1.0"

# ── Actualizar e instalar dependencias mínimas ──────────────
RUN apk update && apk add --no-cache \
    bash \
    gnupg \
    openssl \
    python3 \
    py3-pip \
    coreutils \
    shadow \
    && rm -rf /var/cache/apk/*

# ── Crear usuario sin privilegios (sget_user) ───────────────
# No se utiliza root para ejecutar la aplicación (política de seguridad)
RUN addgroup -S sgetgroup && \
    adduser -S -G sgetgroup -h /home/sget_user -s /bin/bash sget_user

# ── Crear estructura de directorios del módulo ──────────────
RUN mkdir -p /app/logs \
             /app/data \
             /app/keys \
             /app/scripts && \
    chown -R sget_user:sgetgroup /app && \
    chmod 750 /app/logs /app/data && \
    chmod 700 /app/keys

# ── Copiar scripts al contenedor ────────────────────────────
COPY --chown=sget_user:sgetgroup scripts/ /app/scripts/

# Hacer ejecutables los scripts
RUN chmod +x /app/scripts/*.sh /app/scripts/*.py 2>/dev/null || true

# ── Política de seguridad: deshabilitar acceso a root ───────
RUN passwd -l root

# ── Directorio de trabajo ───────────────────────────────────
WORKDIR /app

# ── Cambiar a usuario sin privilegios ───────────────────────
USER sget_user

# ── Variables de entorno del módulo ─────────────────────────
ENV SGET_LOG_DIR=/app/logs
ENV SGET_DATA_DIR=/app/data
ENV SGET_KEYS_DIR=/app/keys
ENV SGET_INTERVAL=5

# ── Puerto de monitoreo (solo informativo) ──────────────────
EXPOSE 8080

# ── Comando de inicio ───────────────────────────────────────
CMD ["bash", "/app/scripts/main.sh"]
