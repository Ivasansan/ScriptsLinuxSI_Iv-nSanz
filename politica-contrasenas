#!/usr/bin/env bash
set -e

# =========================
# Política de contraseñas
# Ubuntu 24.04
# =========================

# Contraseña inicial común (se pedirá al ejecutar)
INITIAL_PASS=""

# Comprobación de root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Ejecuta el script como root (sudo)."
  exit 1
fi

# Pedir contraseña inicial común
read -s -p "Introduce la contraseña inicial común: " INITIAL_PASS
echo
if [[ -z "$INITIAL_PASS" ]]; then
  echo "❌ La contraseña no puede estar vacía."
  exit 1
fi

echo "🔧 Instalando dependencias necesarias..."
apt update -y
apt install -y libpam-pwquality

# -------------------------
# 1) Política de complejidad
# -------------------------
echo "🔐 Configurando política de contraseñas..."

cat > /etc/security/pwquality.conf <<EOF
minlen = 10
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
EOF

# -------------------------
# 2) Bloqueo por intentos fallidos
# -------------------------
echo "⛔ Configurando bloqueo tras intentos fallidos..."

COMMON_AUTH="/etc/pam.d/common-auth"

if ! grep -q pam_faillock.so "$COMMON_AUTH"; then
  sed -i '1i auth required pam_faillock.so preauth silent deny=3 unlock_time=3600' "$COMMON_AUTH"
  sed -i '/^auth\s\+sufficient\s\+pam_unix.so/a auth required pam_faillock.so authfail deny=3 unlock_time=3600' "$COMMON_AUTH"
  sed -i '/^account\s\+required\s\+pam_unix.so/a account required pam_faillock.so' /etc/pam.d/common-account
fi

# -------------------------
# 3) Aplicar a usuarios
# -------------------------
echo "👤 Aplicando política a usuarios..."

USERS=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)

for user in $USERS; do
  echo "$user:$INITIAL_PASS" | chpasswd

  # Forzar cambio de contraseña en el próximo inicio
  chage -d 0 "$user"

  # Caducidad de la cuenta a los 20 días
  chage -E $(date -d "+20 days" +%Y-%m-%d) "$user"
done

echo
echo "✅ Política aplicada correctamente:"
echo "   - Cambio obligatorio de contraseña"
echo "   - Caducidad a los 20 días"
echo "   - Contraseñas complejas (mín. 10 caracteres)"
echo "   - Bloqueo 1 hora tras 3 intentos fallidos"
