#!/usr/bin/env bash
# Configure the adopter without exposing internal DSP file keys.
# Generates installation-config.json, mapLayersConfig.json,
# downloadThemesConfig.json and application.yaml via apply_adopter_config.py.
# Usage: ./config.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"
CONFIG_FILE="$ROOT_DIR/config/adopter/adopter-config.yaml"
EXAMPLE_FILE="$ROOT_DIR/config/adopter/adopter-config.yaml.example"
RER_CONFIG_FILE="$ROOT_DIR/config/adopter/rer-adopter-config.yaml"
RER_ABOUT_FILE="$ROOT_DIR/config/about/overview.rer.md"
APPLY="$ROOT_DIR/scripts/apply_adopter_config.py"

print_config_rebuild_hint() {
  echo ""
  echo "Operational files were written in sibling repositories:"
  echo "  - dsp-backend/config/"
  echo "  - dsp-job-data-migration/config/"
  echo "  - dsp-job-geo-file-generation/config/"
  echo "They are copied into Docker images on the next build."
  echo "Run ./setup.sh or ./start.sh so containers pick up this configuration."
  echo ""
}

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/common.sh"

print_config_intro() {
  echo ""
  echo "Guided Adopter Configuration"
  echo ""
  echo "This wizard collects adopter-specific settings in this order: source database, tables and jobs, application settings, then interface."
  echo "Your configuration is stored in:"
  echo "  $CONFIG_FILE"
  echo ""
  echo "That YAML file is the single source of truth used to generate the operational DSP configuration files."
  echo ""
  echo "Ways to work with this file:"
  echo "  • Use this wizard — step-by-step prompts write answers to the path above"
  echo "  • Bring your own file — copy your adopter-config.yaml to that path, then run ./config.sh and choose 1 (reapply)"
  echo "  • Edit manually — change the YAML in any editor, then run ./config.sh and choose 1 (reapply)"
  echo "  • RER configuration - make DSP connect to the RER application; no need to edit any file."
  echo ""
  echo "The menu below offers reapply (option 1), guided edit (option 2), start over from the template (option 3), or RER configuration (option 4)."
  echo ""
}

apply_rer_configuration() {
  local about_dest
  if [ ! -f "$RER_CONFIG_FILE" ]; then
    error "RER configuration not found: $RER_CONFIG_FILE"
    exit 1
  fi
  if [ ! -f "$RER_ABOUT_FILE" ]; then
    error "RER About page not found: $RER_ABOUT_FILE"
    exit 1
  fi
  cp "$RER_CONFIG_FILE" "$CONFIG_FILE"
  # The preset names overview.rer.md, and the generator only accepts that file
  # when it is already in the backend about directory. The wizard copies it;
  # this path does not, so copy it before generating.
  about_dest="$(dsp_backend_config_dir)/about"
  mkdir -p "$about_dest"
  cp "$RER_ABOUT_FILE" "$about_dest/$(basename "$RER_ABOUT_FILE")"
  python3 "$APPLY" --root "$ROOT_DIR" --config "$CONFIG_FILE"
  echo ""
  echo "The RER configuration is already correct. No further changes are required."
  print_config_rebuild_hint
  exit 0
}

if [ "$#" -gt 0 ]; then
  error "Run ./config.sh with no arguments."
  exit 1
fi

if [ ! -f "$EXAMPLE_FILE" ]; then
  error "Template not found: $EXAMPLE_FILE"
  exit 1
fi

ensure_dotenv
ensure_dsp_repositories --backend --frontend --job --geo-file-job
print_config_intro

echo ""
if [ -f "$CONFIG_FILE" ]; then
  echo "An existing configuration was found."
  echo ""
fi
echo "What do you want to do?"
echo "  1) Reapply the existing configuration (no wizard)"
echo "  2) Edit the existing configuration (wizard with current values)"
echo "  3) Start over from the template (discards current file)"
echo "  4) Apply RER configuration and style"
echo ""
choice=""
read -e -r -p "Choice [1/2/3/4]: " choice || true
case "$choice" in
  1)
    if [ ! -f "$CONFIG_FILE" ]; then
      cp "$EXAMPLE_FILE" "$CONFIG_FILE"
      info "Configuration file created from the example:"
      echo "       $CONFIG_FILE"
    fi
    python3 "$APPLY" --root "$ROOT_DIR" --config "$CONFIG_FILE"
    print_config_rebuild_hint
    exit 0
    ;;
  2)
    if [ -f "$CONFIG_FILE" ]; then
      python3 "$APPLY" --root "$ROOT_DIR" --config "$CONFIG_FILE" --wizard --edit
      print_config_rebuild_hint
      exit 0
    fi
    ;;
  3)
    if [ -f "$CONFIG_FILE" ]; then
      rm -f "$CONFIG_FILE"
    fi
    ;;
  4)
    apply_rer_configuration
    ;;
  *)
    error "Invalid choice: '${choice}' — use 1 (reapply), 2 (edit), 3 (start over), or 4 (RER configuration)."
    exit 1
    ;;
esac

python3 "$APPLY" --root "$ROOT_DIR" --config "$CONFIG_FILE" --wizard
print_config_rebuild_hint
