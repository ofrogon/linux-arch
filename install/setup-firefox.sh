#!/bin/bash

set -euo pipefail

# Masque les boutons (fermer, réduire, maximiser) dans Firefox via userChrome.css.
# Fonctionne pour les profils du dossier ~/.mozilla/firefox.
# Options :
#   --undo : restaure le userChrome.css précédent si un backup a été créé par ce script.

MOZ_DIR="${HOME}/.mozilla/firefox"
PROFILES_INI="${MOZ_DIR}/profiles.ini"
TAG_START="/* >>> hide-window-buttons START <<< */"
TAG_END="/* >>> hide-window-buttons END <<< */"
BACKUP_SUFFIX=".pre-hide-window-buttons.bak"

die() {
  echo "Erreur: $*" >&2
  exit 1
}

ensure_profiles_ini() {
  [[ -f "$PROFILES_INI" ]] || die "profiles.ini introuvable dans ${MOZ_DIR}. Lancez Firefox une fois pour créer un profil."
}

list_profiles_paths() {
  # Retourne les chemins de profils (relatifs à ~/.mozilla/firefox/ si IsRelative=1)
  awk -v moz="$MOZ_DIR" '
    BEGIN{RS=""; FS="\n"}
    /(\[Profile[0-9]+\]|\[Install[^\]]+\])/ {
      rel=path=def=""
      for(i=1;i<=NF;i++){
        if($i ~ /^IsRelative=/){split($i,a,"="); rel=a[2]}
        if($i ~ /^Path=/){split($i,a,"="); path=a[2]}
      }
      if(path!=""){
        print (rel=="1" ? moz "/" path : path)
      }
    }
  ' "$PROFILES_INI"
}

enable_userchrome_pref() {
  local prof_dir="$1"
  mkdir -p "$prof_dir"
  local user_js="${prof_dir}/user.js"
  if [[ -f "$user_js" && ! -w "$user_js" ]]; then
    echo "WARN: ${user_js} non modifiable, saute." >&2
    return
  fi
  if [[ ! -f "$user_js" ]] || ! grep -q 'toolkit\.legacyUserProfileCustomizations\.stylesheets' "$user_js"; then
    echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >>"$user_js"
  fi
}

inject_css() {
  local prof_dir="$1"
  local chrome_dir="${prof_dir}/chrome"
  local ucss="${chrome_dir}/userChrome.css"
  mkdir -p "$chrome_dir"

  # CSS à injecter pour masquer les boutons Firefox (CSD)
  # Couvre plusieurs sélecteurs selon versions (Proton/GTK/Wayland).
  local css_content
  read -r -d '' css_content <<'CSS'
/* >>> hide-window-buttons START <<< */
/* Masque les boutons de fenêtre dans l'UI de Firefox (CSD / Title Bar désactivée). */
:root:not([lwtheme-image]) .titlebar-buttonbox-container,
#titlebar .titlebar-buttonbox-container,
#TabsToolbar .titlebar-buttonbox-container,
.titlebar-buttonbox,
.titlebar-min,
.titlebar-max,
.titlebar-restore,
.titlebar-close {
  display: none !important;
}

/* Certaines variantes d'en-tête (Wayland/GTK headerbar) */
#nav-bar .titlebar-buttonbox-container,
#navigator-toolbox .titlebar-buttonbox-container {
  display: none !important;
}
/* >>> hide-window-buttons END <<< */
CSS

  if [[ -f "$ucss" ]]; then
    # Sauvegarde si pas déjà faite
    if [[ ! -f "${ucss}${BACKUP_SUFFIX}" ]]; then
      cp -a "$ucss" "${ucss}${BACKUP_SUFFIX}"
    fi
    # Retire bloc existant puis réinjecte proprement
    awk -v start="$TAG_START" -v end="$TAG_END" '
      BEGIN{skip=0}
      {
        if(index($0,start)){skip=1; next}
        if(index($0,end)){skip=0; next}
        if(!skip) print
      }
    ' "$ucss" >"${ucss}.tmp"
    printf "%s\n\n%s\n" "$(cat "${ucss}.tmp")" "$css_content" >"$ucss"
    rm -f "${ucss}.tmp"
  else
    printf "%s\n" "$css_content" >"$ucss"
  fi
}

undo_changes() {
  local prof_dir="$1"
  local chrome_dir="${prof_dir}/chrome"
  local ucss="${chrome_dir}/userChrome.css"
  local bak="${ucss}${BACKUP_SUFFIX}"

  if [[ -f "$bak" ]]; then
    cp -a "$bak" "$ucss"
    echo "Restauré: $ucss depuis $bak"
  elif [[ -f "$ucss" ]]; then
    # Sinon, retire seulement le bloc injecté
    awk -v start="$TAG_START" -v end="$TAG_END" '
      BEGIN{skip=0}
      {
        if(index($0,start)){skip=1; next}
        if(index($0,end)){skip=0; next}
        if(!skip) print
      }
    ' "$ucss" >"${ucss}.tmp" && mv "${ucss}.tmp" "$ucss"
    echo "Bloc CSS retiré de: $ucss"
  else
    echo "Rien à annuler pour le profil: $prof_dir"
  fi
}

main() {
  local do_undo=0
  if [[ "${1:-}" == "--undo" ]]; then
    do_undo=1
  elif [[ -n "${1:-}" ]]; then
    echo "Usage: $(basename "$0") [--undo]"
    exit 1
  fi

  ensure_profiles_ini
  mapfile -t profiles < <(list_profiles_paths)

  [[ ${#profiles[@]} -gt 0 ]] || die "Aucun profil trouvé. Vérifiez ${PROFILES_INI}."

  for p in "${profiles[@]}"; do
    # Ne viser que les dossiers de profil (ex: *.default-release)
    if [[ -d "$p" && -f "$p/prefs.js" ]]; then
      echo "Profil: $p"
      if ((do_undo)); then
        undo_changes "$p"
      else
        enable_userchrome_pref "$p"
        inject_css "$p"
        echo "→ CSS appliqué. Redémarrez Firefox pour voir l'effet."
      fi
    fi
  done
  if ((do_undo)); then
    echo "Terminé (undo)."
  else
    echo "Terminé."
  fi
}

main "$@"
