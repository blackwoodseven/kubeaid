###
# In order to use the make file run 'source <projectDir>/env/env.zsh' or 'source <projectDir>/env/env.bash'
# Make sure to set environment variables HELM_REPO_USERNAME and HELM_REPO_PASSWORD
# To use make push a local chartmuseum/helm-push installation is required (https://github.com/chartmuseum/helm-push)
#
# Sample environment variables for ImageConverter chart:
#
# - OX_REMOTE_REPOSITORY_URL: https://registry.open-xchange.com
# - OX_REMOTE_CHART_REPOSITORY_URL: https://registry.open-xchange.com/chartrepo/documents
# - LOCAL_REPOSITORY_NAME: ox-documents-registry
# - HELM_CHART_DIR: helm/core-imageconverter
###

### Chart Repository
# Create a link to the remote repository
init:
	helm registry login -u '${HELM_REPO_USERNAME}' -p ${HELM_REPO_PASSWORD} ${OX_REMOTE_REPOSITORY_URL}
	helm repo add ${LOCAL_REPOSITORY_NAME} ${OX_REMOTE_CHART_REPOSITORY_URL}

# Package the DocumentConverter chart locally. Chart version and appVersion defaults to values from Chart.yaml
package:
	helm dep update
	helm package ${OX_PROJECT_DIR}/${HELM_CHART_DIR} -d ${OX_PROJECT_DIR}/${PACKAGE_TMP_DIR} --app-version ${APP_VERSION} --version ${CHART_VERSION}

# Push to the remote repository if already initialized
push:
	helm push -u '${HELM_REPO_USERNAME}' -p ${HELM_REPO_PASSWORD} ${OX_PROJECT_DIR}/${HELM_CHART_DIR} ${LOCAL_REPOSITORY_NAME}

# Push to OCI registry: login to registry => add local repository => push chart to registry => remove linked, local repository => logout of registry
registry-push:
	helm registry login -u '${HELM_REPO_USERNAME}' -p ${HELM_REPO_PASSWORD} ${OX_REMOTE_REPOSITORY_URL}
	helm repo add ${LOCAL_REPOSITORY_NAME} ${OX_REMOTE_CHART_REPOSITORY_URL}
	helm repo update
	helm push -u '${HELM_REPO_USERNAME}' -p ${HELM_REPO_PASSWORD} ${OX_PROJECT_DIR}/${HELM_CHART_DIR} ${LOCAL_REPOSITORY_NAME}
	helm repo remove ${LOCAL_REPOSITORY_NAME}
	helm registry logout ${OX_REMOTE_REPOSITORY_URL}

# Delete locally packaged chart if any => remove linked, local repository => logout of registry
clean:
	helm repo remove ${LOCAL_REPOSITORY_NAME}
	rm ${OX_PROJECT_DIR}/${PACKAGE_TMP_DIR}/*
	helm registry logout ${OX_REMOTE_REPOSITORY_URL}
