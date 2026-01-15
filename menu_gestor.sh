#!/bin/bash
# autor: jcrequena (base) + adaptado para gestor documental

ROOT="/mnt/gestor"
CURRENT=""
ETAPA=""
CURSO=""

pause() {
  read -p "Pulsa [Enter] para continuar..."
}

error() {
  echo "ERROR: $1"
}

check_root() {
  if [[ ! -d "$ROOT" ]]; then
    error "La ruta ROOT no existe: $ROOT"
    return 1
  fi
  return 0
}

select_ruta_curso() {
  check_root || return 1

  echo "Ruta actual ROOT: $ROOT"
  echo
  echo "Selecciona etapa:"
  echo "1) ESO"
  echo "2) BACH"
  echo "3) DAW"
  read -p "Opción: " op

  case "$op" in
    1) ETAPA="ESO";  cursos=(1ESO 2ESO 3ESO 4ESO) ;;
    2) ETAPA="BACH"; cursos=(1BACH 2BACH) ;;
    3) ETAPA="DAW";  cursos=(1DAW) ;;
    *) error "Opción no válida"; return 1 ;;
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
    error "Selección inválida"
    return 1
  fi

  CURSO="${cursos[$((n-1))]}"
  CURRENT="$ROOT/$ETAPA/$CURSO"

  if [[ ! -d "$CURRENT" ]]; then
    error "No existe la ruta: $CURRENT"
    return 1
  fi

  echo
  echo "Ruta seleccionada: $CURRENT"
}

listar_archivos() {
  [[ -z "$CURRENT" ]] && { error "No hay curso seleccionado"; return 1; }
  ls -la "$CURRENT"
}

crear_archivo() {
  [[ -z "$CURRENT" ]] && { error "No hay curso seleccionado"; return 1; }
  read -p "Nombre del archivo a crear: " f
  touch "$CURRENT/$f" 2>/dev/null || error "No se pudo crear (¿permisos?)"
}

eliminar_archivo() {
  [[ -z "$CURRENT" ]] && { error "No hay curso seleccionado"; return 1; }
  read -p "Nombre del archivo a eliminar: " f
  rm -i "$CURRENT/$f" 2>/dev/null || error "No se pudo eliminar (¿permisos?)"
}

#################################
# PROGRAMA PRINCIPAL
#################################

while true; do
  clear
  echo "****************************"
  echo "****** MENU GESTOR *********"
  echo "****************************"
  echo
  echo "ROOT:  $ROOT"
  echo "CURSO: ${CURRENT:-<no seleccionado>}"
  echo
  echo "1) Seleccionar etapa y curso"
  echo "2) Listar archivos"
  echo "3) Crear archivo"
  echo "4) Eliminar archivo"
  echo "5) Salir"
  echo

  read -p "Introduce una opción: " opcion

  case "$opcion" in
    1) select_ruta_curso; pause ;;
    2) listar_archivos; pause ;;
    3) crear_archivo; pause ;;
    4) eliminar_archivo; pause ;;
    5) echo "Saliendo..."; exit 0 ;;
    *) echo "Opción inválida"; pause ;;
  esac
done
