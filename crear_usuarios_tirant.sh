#!/usr/bin/env bash
set -e

# =========================
# Creacion de usuarios y grupos
# Centro de Supercomputacion Tirant
# =========================

# Comprobar que se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ejecuta el script como root (sudo)"
  exit 1
fi

# Archivos CSV
CSV_FILES=("procesos_evaluacion.csv" "admin_sistemas.csv")

for CSV in "${CSV_FILES[@]}"; do

  # Comprobar que el CSV existe
  if [[ ! -f "$CSV" ]]; then
    echo "❌ No se encuentra el archivo $CSV"
    exit 1
  fi

  # Leer CSV (saltando cabecera)
  tail -n +2 "$CSV" | while IFS=',' read -r \
    Name Surname1 Surname2 account DNI Department Enabled Password TurnPassDays email Description
  do

    # Saltar lineas vacias o mal formadas
    [[ -z "$account" || -z "$Department" ]] && continue

    # Crear grupo si no existe
    if ! getent group "$Department" >/dev/null; then
      groupadd "$Department"
      echo "Grupo creado: $Department"
    fi

    # Crear usuario si no existe
    if ! id "$account" &>/dev/null; then

      # Comentario seguro (sin caracteres raros)
      USER_COMMENT="$Name $Surname1 $Surname2"
      USER_COMMENT=$(echo "$USER_COMMENT" | tr -cd '[:alnum:] ')

      useradd -m \
        -g "$Department" \
        -s /bin/bash \
        -c "$USER_COMMENT" \
        "$account"

      echo "Usuario creado: $account"

      # Asignar contrasena inicial
      echo "$account:$Password" | chpasswd

      # Forzar cambio de contrasena en el primer inicio
      chage -d 0 "$account"

      # Caducidad de la cuenta
      chage -E "$(date -d "+$TurnPassDays days" +%Y-%m-%d)" "$account"

      # Bloquear cuenta si esta deshabilitada
      if [[ "$Enabled" != "yes" ]]; then
        usermod -L "$account"
      fi

    else
      echo "El usuario $account ya existe"
    fi

  done
done

echo
echo "✅ Usuarios y grupos creados correctamente"
