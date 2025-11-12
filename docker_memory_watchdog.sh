docker_memory_watchdog.sh
#!/bin/bash

# CONFIGURACIÓN
MEMORY_LIMIT_MB=2048 # Límite de memoria en MB por contenedor (2GB)
LOG_FILE="/var/log/docker_memory_watchdog.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Validar si docker está corriendo
if ! pgrep -x "dockerd" > /dev/null; then
    echo "[$TIMESTAMP] ❌ Docker no está corriendo. Abortando." | tee -a $LOG_FILE
    exit 1
fi

# Obtener lista de contenedores activos
CONTAINERS=$(docker ps --format '{{.ID}} {{.Names}}')

if [[ -z "$CONTAINERS" ]]; then
    echo "[$TIMESTAMP] ℹ️ No hay contenedores en ejecución." | tee -a $LOG_FILE
    exit 0
fi

# Loop por contenedor
echo "[$TIMESTAMP] 🚨 Iniciando monitoreo de contenedores..." | tee -a $LOG_FILE

while read -r CONTAINER_ID CONTAINER_NAME; do
    MEM_USAGE_BYTES=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID | awk '{print $1}' | sed 's/[^0-9.]//g')
    MEM_UNIT=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID | awk '{print $1}' | sed 's/[0-9.]//g')

    # Convertir a MB
    case $MEM_UNIT in
        kB) MEM_MB=$(echo "$MEM_USAGE_BYTES / 1024" | bc) ;;
        MB) MEM_MB=$(echo "$MEM_USAGE_BYTES" | bc) ;;
        GB) MEM_MB=$(echo "$MEM_USAGE_BYTES * 1024" | bc) ;;
        *) MEM_MB=0 ;;
    esac

    if (( MEM_MB > MEMORY_LIMIT_MB )); then
        echo "[$TIMESTAMP] ⚠️ Contenedor '$CONTAINER_NAME' ($CONTAINER_ID) usa $MEM_MB MB > $MEMORY_LIMIT_MB MB. Matando contenedor..." | tee -a $LOG_FILE
        docker kill $CONTAINER_ID
    else
        echo "[$TIMESTAMP] ✔️ Contenedor '$CONTAINER_NAME' usa $MEM_MB MB. OK." >> $LOG_FILE
    fi
done <<< "$CONTAINERS"
