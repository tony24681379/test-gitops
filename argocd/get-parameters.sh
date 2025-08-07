#!/usr/bin/sh
ARGUMENTS=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select(.name == "values-files").array | .[] ')
PARAMETERS=$(echo "$ARGOCD_APP_PARAMETERS" | jq -r '.[] | select((.name != "values-files" and .name != "helm-parameters")) | "\(.name)=\(.string)"')
PARAMETERS_FROM_FILE=$(echo "$ARGUMENTS" | xargs -r yq e -o=p values*.yaml)
PARAMETERS="$PARAMETERS\n$PARAMETERS_FROM_FILE"
echo "$PARAMETERS" | jq --slurp --raw-input \
  'split("\n") | map(capture("(?<name>.*) = (?<string>.*)")) | [. | group_by(.name)[] | .[-1]] | .[] |= .+ {"collectionType": "string"}'
