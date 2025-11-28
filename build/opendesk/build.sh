#!/usr/bin/env bash

set -euo pipefail

if [[ -z "$1" ]]; then
  echo "Usage: $0 <target-directory>"
  exit 1
fi

TARGET_DIR="$1"
VALUES_FILE="$TARGET_DIR/values-opendesk.yaml"
OPENDESK_DIR="$TARGET_DIR/../opendesk"
ESSENTIALS_DIR="$TARGET_DIR/../opendesk-essentials"

mkdir -p "$OPENDESK_DIR"/{chat,mail,nextcloud,openproject,xwiki,jitsi}
mkdir -p "$ESSENTIALS_DIR"

cd "versions/v1.6.0"

generate_selector_flags() {
    local apps_list="$1"
    local flags=()
    # Read the comma separated list into an array
    IFS=',' read -r -a APP_ARRAY <<< "$apps_list"

    # Build an array of selector flags
    for app_name in "${APP_ARRAY[@]}"; do
        flags+=("--selector" "name=$app_name")
    done
    # Echo flags for command substitution
    echo "${flags[@]}"
}

CORE_APPS="postgresql,mariadb,redis,memcached,minio,nginx-s3-gateway,cassandra,nubus,ums,opendesk-keycloak-bootstrap,intercom-service,opendesk-certificates,clamav,clamav-simple,opendesk-otterize,opendesk-static-files,opendesk-well-known,migrations-pre,migrations-post,opendesk-home,opendesk-alerts,opendesk-dashboards"

OPENDESK_FILES="opendesk-nextcloud,opendesk-nextcloud-management,opendesk-nextcloud-notifypush,collabora-online,collabora-controller,cryptpad,notes"

OPENDESK_MAIL="postfix,postfix-ox,dovecot,opendesk-dkimpy-milter,open-xchange,opendesk-open-xchange-bootstrap,ox-connector"

OPENDESK_CHAT="opendesk-element,opendesk-synapse,opendesk-synapse-web,opendesk-synapse-adminbot-bootstrap,opendesk-synapse-auditbot-bootstrap,opendesk-synapse-adminbot-web,opendesk-synapse-adminbot-pipe,opendesk-synapse-auditbot-pipe,matrix-user-verification-service-bootstrap,matrix-user-verification-service,matrix-neoboard-widget,matrix-neochoice-widget,matrix-neodatefix-widget,matrix-neodatefix-bot-bootstrap,matrix-neodatefix-bot"

OPENDESK_PROJECTS="opendesk-openproject-bootstrap,openproject,opendesk-synapse-admin,opendesk-synapse-groupsync"

OPENDESK_VIDEO="jitsi"

OPENDESK_XWIKI="xwiki"


echo "Generating core essential apps manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$CORE_APPS") > "${ESSENTIALS_DIR}/opendesk-essentials.yaml"

echo "Generating nextcloud manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_FILES") > "${OPENDESK_DIR}/nextcloud/nextcloud.yaml"

echo "Generating matrix chat manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_CHAT") > "${OPENDESK_DIR}/chat/chat.yaml"

echo "Generating mail manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_MAIL") > "${OPENDESK_DIR}/mail/mail.yaml"

echo "Generating openproject manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_PROJECTS") > "${OPENDESK_DIR}/openproject/openproject.yaml"

echo "Generating xwiki manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_XWIKI") > "${OPENDESK_DIR}/xwiki/xwiki.yaml"

echo "Generating jitsi manifest..."
helmfile template -e default -n opendesk --state-values-file "../../default-values/values.yaml" --state-values-file "${VALUES_FILE}" \
  $(generate_selector_flags "$OPENDESK_VIDEO") > "${OPENDESK_DIR}/jitsi/jitsi.yaml"



# Fix hook annotations and ttlSecondsAfterFinished for both files
fix_hooks_and_ttl() {
  local file=$1
  sed -i \
    -e 's/helm\.sh\/hook: .*/"managed-by": "helmfile"/g' \
    -e 's/"helm\.sh\/hook": .*/"argocd.argoproj.io\/hook": "Sync"/g' \
    -e 's/"argocd.argoproj.io\/hook":.*/"managed-by": "helmfile"/g' \
    -e 's/argocd.argoproj.io\/hook:.*/"managed-by": "helmfile"/g' \
    -e '/helm\.sh\/hook-delete-policy/d' \
    -e '/argocd.argoproj.io\/hook-delete-policy/d' \
    -e '/ttlSecondsAfterFinished/d' \
    "$file"
  echo "Fixed hooks and TTL in $file"
}

fix_hooks_and_ttl "${ESSENTIALS_DIR}/opendesk-essentials.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/nextcloud/nextcloud.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/chat/chat.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/mail/mail.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/openproject/openproject.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/xwiki/xwiki.yaml"
fix_hooks_and_ttl "${OPENDESK_DIR}/jitsi/jitsi.yaml"

# Append static template only to dependent apps
cat ../../templates/openebs-tmp-hostpath.yaml >> "${ESSENTIALS_DIR}/opendesk-essentials.yaml"
