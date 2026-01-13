#!/usr/bin/env bash
set -euo pipefail

ROOT="/mnt/gestor"

# --- 0) Comprobación ---
if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta como root: sudo $0"
  exit 1
fi

echo "[1/6] Creando grupos (si no existen)..."
for g in ESO BACH DAW; do
  getent group "$g" >/dev/null || groupadd "$g"
done

echo "[2/6] Creando usuarios (si no existen) y asignando grupo principal..."
create_user () {
  local u="$1" g="$2"
  if id "$u" &>/dev/null; then
    echo "  - Usuario $u ya existe"
  else
    useradd -m -g "$g" "$u"
    echo "  - Creado usuario $u (grupo $g)"
  fi
}

create_user 1ESO  ESO
create_user 2ESO  ESO
create_user 3ESO  ESO
create_user 4ESO  ESO

create_user 1BACH BACH
create_user 2BACH BACH

create_user 1DAW  DAW

# (Opcionales del enunciado)
# useradd -m alumnado 2>/dev/null || true
# useradd -m profesorado 2>/dev/null || true
# useradd -m -G sudo administrador 2>/dev/null || true

echo "[3/6] Creando estructura de directorios..."
mkdir -p "$ROOT"/{ESO/{1ESO,2ESO,3ESO,4ESO},BACH/{1BACH,2BACH},DAW/1DAW}

echo "[4/6] Ajustando permisos de carpetas de etapa (sin acceso entre etapas)..."
chown -R root:ESO  "$ROOT/ESO"
chown -R root:BACH "$ROOT/BACH"
chown -R root:DAW  "$ROOT/DAW"

chmod 750 "$ROOT/ESO" "$ROOT/BACH" "$ROOT/DAW"

echo "[5/6] Ajustando propietarios y permisos de carpetas de curso..."
# ESO
chown 1ESO:ESO "$ROOT/ESO/1ESO"
chown 2ESO:ESO "$ROOT/ESO/2ESO"
chown 3ESO:ESO "$ROOT/ESO/3ESO"
chown 4ESO:ESO "$ROOT/ESO/4ESO"
chmod 750 "$ROOT/ESO"/{1ESO,2ESO,3ESO,4ESO}

# BACH
chown 1BACH:BACH "$ROOT/BACH/1BACH"
chown 2BACH:BACH "$ROOT/BACH/2BACH"
chmod 750 "$ROOT/BACH"/{1BACH,2BACH}

# DAW
chown 1DAW:DAW "$ROOT/DAW/1DAW"
chmod 750 "$ROOT/DAW/1DAW"

echo "[6/6] Listo ✅"
echo "Ahora pon contraseñas con: sudo passwd 1ESO (y así con cada usuario)"
echo "Consejo: prueba accesos con 'su - 1ESO' y 'ls /mnt/gestor/ESO/2ESO' etc."
