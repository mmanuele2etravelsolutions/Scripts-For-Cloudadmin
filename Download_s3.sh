#!/bin/bash

echo "Script para descargar un archivo desde un bucket S3"
echo "Requiere AWS CLI previamente configurado (aws configure)"
echo "By Mmanuel"

echo "=========================================="
echo "   DESCARGAR ARCHIVO DESDE AWS S3"
echo "=========================================="
echo ""
read -p "👉 Ingrese la ruta completa del archivo en S3 (ejemplo: s3://NAMES3/html.zip): " s3_path

    # Cambiar NAMES3 por nombre de S3

# Validar que el usuario ingresó algo
if [ -z "$s3_path" ]; then
    echo "❌ No ingresaste ninguna ruta. Saliendo..."
    exit 1
fi

# Descargar el archivo en el directorio actual
echo "⏳ Descargando archivo desde $s3_path ..."
aws s3 cp "$s3_path" .

# Verificar si la descarga fue exitosa
if [ $? -eq 0 ]; then
    echo "✅ Archivo descargado correctamente en $(pwd)"
else
    echo "❌ Error al descargar el archivo."
fi
