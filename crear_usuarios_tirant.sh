#!/usr/bin/env bash
set -e

# =========================
# Creación de usuarios tipo
# Centro de Supercomputación Tirant
# =========================

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ejecuta el script como root (sudo)."
  exit 1
fi

CSV_FILES=("procesos_evaluacion.csv" "admin_sistemas.csv")

for CSV in "${CSV_FILES[@]}"; do
  if [[ ! -f "$CSV" ]]; then
    echo "❌ No se encuentra el archivo $CSV"
    exit 1
  fi

  tail -n +2 "$CSV" | while IFS=',' read -r \
    Name Surname1 Surname2 account DNI Department Enabled Password TurnPassDays email Description
  do

    # Crear grupo si no existe
    if ! getent group "$Department" > /dev/null; then
      groupadd "$Department"
      echo "✅ Grupo creado: $Department"
    fi

    # Crear usuario si no existe
    if ! id "$account" &>/dev/null; then
      useradd -m \
        -g "$Department" \
        -s /bin/bash \
        -c "$Description ($Name $Surname1 $Surname2 - DNI: $DNI)" \
        "$account"

      echo "✅ Usuario creado: $account"

      # Contraseña inicial
      echo "$account:$Password" | chpasswd

      # Forzar cambio de contraseña
      chage -d 0 "$account"

      # Caducidad de cuenta
      chage -E "$(date -d "+$TurnPassDays days" +%Y-%m-%d)" "$account"

      # Bloquear cuenta si está deshabilitada
      if [[ "$Enabled" != "yes" ]]; then
        usermod -L "$account"
      fi
    else
      echo "ℹ️ El usuario $account ya existe"
    fi

  done
done

echo
echo "🎉 Usuarios y grupos creados correctamente según la estructura del centro Tirant."
