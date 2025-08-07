#!/usr/bin/sh

# echo $ARGOCD_APP_PARAMETERS

# Convert JSON parameters to comma-delimited k=v pairs.
PARAMETERS=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select((.name != "values-files" and .name != "helm-parameters" and .name != "helm-ssm-values-files" and .name != "helm-repo" and .name != "helm-chart" and .name != "version" and .name != "release-name" and .name != "post-renderer")) | "--set \(.name)=\(.string)"')

# Convert the values-files parameter value to a newline-delimited list of Helm CLI arguments.
VALUE_FILES=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "values-files").array | .[] | "--values " + .')

HELM_SSM_VALUE_FILES=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "helm-ssm-values-files").array | .[] | "--values " + .')
if [ "$HELM_SSM_VALUE_FILES" != "" ]; then
    echo $HELM_SSM_VALUE_FILES | xargs -r helm ssm;
fi

# Convert the helm-repo parameter value to a newline-delimited list of Helm CLI arguments.
HELM_REPO=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "helm-repo") | "--repo \(.string)"')

# Convert the helm-chart parameter value to a newline-delimited list of Helm CLI arguments.
HELM_CHART=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "helm-chart") | "\(.string)"')
if [ "$HELM_CHART" = "" ]; then HELM_CHART="."; fi

# Convert the helm chart version parameter value to a newline-delimited list of Helm CLI arguments.
HELM_CHART_VERSION=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "version") | "--version \(.string)"')

# Convert the helm release name parameter value to a newline-delimited list of Helm CLI arguments.
HELM_RELEASE_NAME=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "release-name") | "--release-name \(.string)"')

# Convert the helm post renderer parameter value to a newline-delimited list of Helm CLI arguments.
HELM_POST_RENDERER=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "post-renderer") | "\(.string)"')

# Add parameters to the arguments variable.
ARGUMENTS="$VALUE_FILES $HELM_SSM_VALUE_FILES $PARAMETERS $HELM_RELEASE_NAME $HELM_CHART_VERSION $HELM_REPO"

if [ "$HELM_POST_RENDERER" != "" ]; then
    helm template $ARGUMENTS $HELM_CHART -n $ARGOCD_APP_NAMESPACE | $HELM_POST_RENDERER
else
    helm template $ARGUMENTS $HELM_CHART -n $ARGOCD_APP_NAMESPACE
fi

