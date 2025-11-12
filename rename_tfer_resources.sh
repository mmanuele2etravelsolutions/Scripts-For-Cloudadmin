#!/bin/bash
# ===========================================================
# Script: rename_tfer_resources_global.sh
# Autor: MManuel (adaptado por MAX)
# Función:
#   Limpia los nombres de recursos generados por Terraformer
#   en TODOS los .tf del proyecto (incluyendo subcarpetas).
# ===========================================================

echo "🔍 Iniciando búsqueda recursiva de archivos .tf en: $(pwd)"
echo "-----------------------------------------------------------"

# Buscar todos los archivos .tf recursivamente
find . -type f -name "*.tf" | while read -r file; do
  echo "🧩 Procesando: $file"
  
  # Realizar reemplazos directamente sobre el archivo
  sed -i \
    -e 's/tfer--//g' \
    -e 's/-0020-/-/g' \
    -e 's/_0020_/-/g' \
    -e 's/-002D-/-/g' \
    -e 's/_002D_/-/g' \
    -e 's/_002E_/\./g' \
    -e 's/_002A_/*/g' \
    -e 's/_002F_/\//g' \
    "$file"
done

echo "-----------------------------------------------------------"
echo "✅ Limpieza completada en todos los .tf del proyecto."
