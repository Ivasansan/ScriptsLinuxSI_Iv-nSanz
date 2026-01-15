#!/bin/bash
# autor: jcrequena (base) + adaptado por Iván
# Gestor Documental - Usuarios, estructura, permisos + menú de gestión de ficheros

#################################
# VARIABLES GLOBALES
#################################
ROOT="/mnt/gestor"

ETAPA=""
CURSO=""
CURRENT=""

USUARIOS_ESO=(1ESO 2ESO 3ESO 4ESO)
USUARIOS_BACH=(1BACH 2BACH)
USUARIOS_DAW=(1DAW)

GRUPOS=(ESO BACH DAW)

#################################
# FUNCIONES AUXILIARES
#################################
pause() { read -p "Pulse [Enter] para continuar..."; }

cabecera() {
  clear
  echo "Bienvenido $(whoami)"
  echo
  date
  echo
  echo "***********************************************"
  echo "**** Usuarios locales - Gestor Documental *****"
  echo "***********************************************"
  echo
}

msg_error() { echo "ERROR: $1"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    msg_error "Esta opción requiere permisos de administrador. Ejecuta con: sudo ./gestor_menu.sh"
    return 1
  fi
  return 0
}

check_root_path() {
  if [[ ! -d "$ROOT" ]]; then
    msg_error "No existe la ruta ROOT: $ROOT"
    return 1
  fi
  return 0
}

#################################
# FUNCIONES EXTRA: SELECCIÓN RUTA + GESTIÓN ARCHIVOS
#################################

fntSeleccionarEtapaCurso() {
  echo "Ruta actual ROOT: $ROOT"
  echo
  echo "Selecciona etapa:"
  echo "1) ESO"
  echo "2) BACH"
  echo "3) DAW"
  read -p "Opción: " op

  case "$op" in
    1) ETAPA="ESO";  cursos=( "${USUARIOS_ESO[@]}" ) ;;
    2) ETAPA="BACH"; cursos=( "${USUARIOS_BACH[@]}" ) ;;
    3) ETAPA="DAW";  cursos=( "${USUARIOS_DAW[@]}" ) ;;
    *) msg_error "Opción no válida"; return 1 ;;
  esac

  echo
  echo "Cursos disponibles en $ETAPA:"
  i=1
  for c in "${cursos[@]}"; do
    echo "$i) $c"
    ((i++))
  done

  read -p "Elige curso (número): " n
  if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 || n > ${#cursos[@]} )); then
    msg_error "Selección inválida"
    return 1
  fi

  CURSO="${cursos[$((n-1))]}"
  CURRENT="$ROOT/$ETAPA/$CURSO"

  # OJO: si no tienes permisos de entrada, -d puede fallar y parecer "no existe".
  if [[ ! -d "$CURRENT" ]]; then
    msg_error "No existe o no es accesible la ruta: $CURRENT"
    msg_error "Ejecuta la gestión de archivos como usuario del curso (su - 2ESO) o con sudo para comprobar."
    return 1
  fi

  echo "Ruta seleccionada: $CURRENT"
  return 0
}

fntListarArchivos() {
  if [[ -z "$CURRENT" ]]; then
    msg_error "No hay curso seleccionado. Selecciona etapa y curso primero."
    return 1
  fi
  echo "Listado de: $CURRENT"
  ls -la "$CURRENT"
}

fntCrearArchivo() {
  if [[ -z "$CURRENT" ]]; then
    msg_error "No hay curso seleccionado. Selecciona etapa y curso primero."
    return 1
  fi
  read -p "Nombre del archivo a crear (ej. nota.txt): " fname
  [[ -z "$fname" ]] && { msg_error "Nombre vacío"; return 1; }

  touch "$CURRENT/$fname" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    msg_error "No se pudo crear (¿permisos?)"
    return 1
  fi
  echo "Archivo creado: $CURRENT/$fname"
}

fntEliminarArchivo() {
  if [[ -z "$CURRENT" ]]; then
    msg_error "No hay curso seleccionado. Selecciona etapa y curso primero."
    return 1
  fi
  read -p "Nombre del archivo a eliminar: " fname
  [[ -z "$fname" ]] && { msg_error "Nombre vacío"; return 1; }

  rm -i "$CURRENT/$fname" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    msg_error "No se pudo eliminar (¿no existe? ¿permisos?)"
    return 1
  fi
  echo "Operación finalizada."
}

# Submenú: Gestión de archivos (funcionalidad extra)
fntMenuGestionArchivos() {
  local op2=""
  while true; do
    clear
    echo "************ GESTIÓN DE ARCHIVOS ************"
    echo "ROOT:  $ROOT"
    echo "RUTA:  ${CURRENT:-<no seleccionada>}"
    echo
    echo "1) Seleccionar etapa y curso"
    echo "2) Listar archivos"
    echo "3) Crear archivo"
    echo "4) Eliminar archivo"
    echo "5) Volver"
    echo
    read -p "Seleccione [1-5]: " op2

    case "$op2" in
      1) fntSeleccionarEtapaCurso; pause ;;
      2) fntListarArchivos; pause ;;
      3) fntCrearArchivo; pause ;;
      4) fntEliminarArchivo; pause ;;
      5) break ;;
      *) echo "Opción no válida"; pause ;;
    esac
  done
}

#################################
# OPCIÓN 1: USUARIOS / GRUPOS (crear + borrar)
#################################

fntCrearUsuariosGrupos() {
  require_root || return 1

  echo "Creando grupos (si no existen)..."
  for g in "${GRUPOS[@]}"; do
    getent group "$g" >/dev/null || groupadd "$g"
  done

  echo "Creando usuarios (si no existen)..."
  for u in "${USUARIOS_ESO[@]}"; do id "$u" &>/dev/null || useradd -m -g ESO "$u"; done
  for u in "${USUARIOS_BACH[@]}"; do id "$u" &>/dev/null || useradd -m -g BACH "$u"; done
  for u in "${USUARIOS_DAW[@]}"; do id "$u" &>/dev/null || useradd -m -g DAW "$u"; done

  echo "Usuarios y grupos creados correctamente."
  echo "Recuerda asignar contraseñas con: sudo passwd 1ESO (y así con el resto)."
}

fntBorrarUsuariosGrupos() {
  require_root || return 1

  read -p "¿Seguro que desea BORRAR usuarios y grupos del proyecto? (s/n): " resp
  [[ "$resp" != "s" ]] && { echo "Operación cancelada."; return 0; }

  echo "Borrando usuarios..."
  # userdel -r borra también /home/usuario
  for u in "${USUARIOS_ESO[@]}" "${USUARIOS_BACH[@]}" "${USUARIOS_DAW[@]}"; do
    id "$u" &>/dev/null && userdel -r "$u"
  done

  echo "Borrando grupos..."
  for g in "${GRUPOS[@]}"; do
    getent group "$g" >/dev/null && groupdel "$g"
  done

  echo "Usuarios y grupos eliminados."
}

fntMenuUsuariosGrupos() {
  require_root || return 1
  local op=""
  while true; do
    clear
    echo "******** USUARIOS / GRUPOS LOCALES ********"
    echo
    echo "1) Crear usuarios y grupos"
    echo "2) Borrar usuarios y grupos"
    echo "3) Volver"
    echo
    read -p "Seleccione [1-3]: " op
    case "$op" in
      1) fntCrearUsuariosGrupos; pause ;;
      2) fntBorrarUsuariosGrupos; pause ;;
      3) break ;;
      *) echo "Opción no válida"; pause ;;
    esac
  done
}

#################################
# OPCIÓN 2: CREACIÓN GESTOR DOCUMENTAL + PERMISOS
#################################
fntCrearGestorDocumental() {
  require_root || return 1

  echo "Creando estructura del gestor documental en: $ROOT"
  mkdir -p "$ROOT/ESO"/{1ESO,2ESO,3ESO,4ESO}
  mkdir -p "$ROOT/BACH"/{1BACH,2BACH}
  mkdir -p "$ROOT/DAW/1DAW"

  echo "Asignando propietarios y permisos por etapa..."
  chown -R root:ESO  "$ROOT/ESO"
  chown -R root:BACH "$ROOT/BACH"
  chown -R root:DAW  "$ROOT/DAW"

  chmod 750 "$ROOT/ESO" "$ROOT/BACH" "$ROOT/DAW"

  echo "Asignando propietarios y permisos por curso..."
  chown 1ESO:ESO  "$ROOT/ESO/1ESO"
  chown 2ESO:ESO  "$ROOT/ESO/2ESO"
  chown 3ESO:ESO  "$ROOT/ESO/3ESO"
  chown 4ESO:ESO  "$ROOT/ESO/4ESO"
  chmod 750 "$ROOT/ESO"/*

  chown 1BACH:BACH "$ROOT/BACH/1BACH"
  chown 2BACH:BACH "$ROOT/BACH/2BACH"
  chmod 750 "$ROOT/BACH"/*

  chown 1DAW:DAW "$ROOT/DAW/1DAW"
  chmod 750 "$ROOT/DAW/1DAW"

  echo "Gestor documental creado y permisos aplicados."
}

#################################
# OPCIÓN 3: BORRADO GESTOR + RESET PERMISOS
#################################
fntBorrarGestorDocumental() {
  require_root || return 1

  read -p "¿Seguro que desea borrar el gestor documental (carpetas)? (s/n): " resp
  if [[ "$resp" == "s" ]]; then
    rm -rf "$ROOT"
    echo "Gestor documental eliminado."
  else
    echo "Operación cancelada."
  fi
}

# NUEVO: Reset de permisos para vídeo (quita la configuración del proyecto sin borrar carpetas)
fntResetPermisos() {
  require_root || return 1
  check_root_path || return 1

  read -p "¿Seguro que desea RESETEAR permisos del gestor (sin borrar carpetas)? (s/n): " resp
  [[ "$resp" != "s" ]] && { echo "Operación cancelada."; return 0; }

  echo "Reseteando propietarios a root:root..."
  chown -R root:root "$ROOT"

  echo "Reseteando permisos a 755..."
  chmod -R 755 "$ROOT"

  # Por si en algún momento usaste ACL (opcional, no molesta si no existe)
  if command -v setfacl >/dev/null 2>&1; then
    echo "Eliminando ACL (si existían)..."
    setfacl -Rb "$ROOT" 2>/dev/null || true
  fi

  echo "Permisos reseteados. Ahora cualquier usuario con acceso al punto de montaje podrá listar."
  echo "Para volver a aplicar los permisos del proyecto, ejecuta la opción 2."
}

fntMenuBorradoReset() {
  require_root || return 1
  local op=""
  while true; do
    clear
    echo "******** BORRADO / RESET ********"
    echo
    echo "1) Borrar Gestor Documental (rm -rf $ROOT)"
    echo "2) Resetear permisos (sin borrar carpetas)"
    echo "3) Volver"
    echo
    read -p "Seleccione [1-3]: " op
    case "$op" in
      1) fntBorrarGestorDocumental; pause ;;
      2) fntResetPermisos; pause ;;
      3) break ;;
      *) echo "Opción no válida"; pause ;;
    esac
  done
}

#################################
# OPCIÓN 4: AYUDA + GESTIÓN ARCHIVOS
#################################
fntAyuda() {
  echo "AYUDA"
  echo
  echo "1) Usuarios/Grupos: crea o elimina cuentas y grupos del proyecto."
  echo "2) Gestor Documental: crea la estructura de carpetas y aplica permisos."
  echo "3) Borrado/Reset: borra el gestor o resetea permisos para repetir pruebas."
  echo
  echo "Funcionalidad extra: Gestión de archivos (seleccionar etapa/curso, listar, crear y eliminar)."
  echo
  echo "Recomendación: la gestión de archivos se prueba mejor ejecutando el script como el usuario del curso (su - 1ESO)."
  echo
  read -p "¿Desea abrir el menú de Gestión de Archivos ahora? (s/n): " resp
  [[ "$resp" == "s" ]] && fntMenuGestionArchivos
}

#################################
# PROGRAMA PRINCIPAL (MENÚ IGUAL QUE EN LA FOTO)
#################################
opcion=""

while true; do
  cabecera
  echo "Selecciona la opción deseada"
  echo
  echo "1. Creación de usuarios-grupos locales"
  echo "2. Creación Gestor Documental"
  echo "3. Borrado Gestor Documental"
  echo "4. Ayuda"
  echo "5. SALIR"
  echo
  read -p "Seleccione la operación a realizar [1-5]: " opcion

  case "$opcion" in
    1) fntMenuUsuariosGrupos; pause ;;
    2) fntCrearGestorDocumental; pause ;;
    3) fntMenuBorradoReset; pause ;;
    4) fntAyuda; pause ;;
    5) echo "Saliendo de la aplicación..."; exit 0 ;;
    *) echo "Opción no válida"; pause ;;
  esac
done

