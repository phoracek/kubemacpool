#!/bin/bash

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

set -euo pipefail

script_dir="$(readlink -f $(dirname $0))"
source "${script_dir}"/common.sh
source "${script_dir}"/config.sh

#all generated files are placed in manifests/generated
function generateResourceManifest {
    codeGroup=$3
    filename=$4
    generator=$1
    targetDir=$2

    manifestName=$filename
    manifestNamej2=$filename".j2"

    rm -rf ${targetDir}/$manifestName
    rm -rf ${targetDir}/$manifestNamej2
    (${generator} -code-group=${codeGroup} \
        -docker-repo="${DOCKER_PREFIX}" \
        -docker-tag="${DOCKER_TAG}" \
        -deploy-cluster-resources="true" \
        -operator-image="${OPERATOR_IMAGE_NAME}" \
        -controller-image="${CONTROLLER_IMAGE_NAME}" \
        -importer-image="${IMPORTER_IMAGE_NAME}" \
        -cloner-image="${CLONER_IMAGE_NAME}" \
        -apiserver-image=${APISERVER_IMAGE_NAME} \
        -uploadproxy-image=${UPLOADPROXY_IMAGE_NAME} \
        -uploadserver-image=${UPLOADSERVER_IMAGE_NAME} \
        -csv-version=${CSV_VERSION} \
        -cdi-logo-path=${CDI_LOGO_PATH} \
        -quay-namespace="${QUAY_NAMESPACE}" \
        -quay-repository="${QUAY_REPOSITORY}" \
        -verbosity="${VERBOSITY}" \
        -pull-policy="${PULL_POLICY}" \
        -namespace="${NAMESPACE}"
    ) 1>>"${targetDir}/"$manifestName

    (${generator} -code-group=${codeGroup} \
        -docker-repo="{{ docker_prefix }}" \
        -docker-tag="{{ docker_tag }}" \
        -deploy-cluster-resources="true" \
        -operator-image="{{ operator_image_name }}" \
        -controller-image="{{ controller_image }}" \
        -importer-image="{{ importer_image }}" \
        -cloner-image="{{ cloner_image }}" \
        -apiserver-image="{{ apiserver_image }}" \
        -uploadproxy-image="{{ uploadproxy_image }}" \
        -uploadserver-image="{{ uploadserver_image }}" \
        -csv-version=${CSV_VERSION} \
        -cdi-logo-path=${CDI_LOGO_PATH} \
        -quay-namespace="{{ quay_namespace }}}" \
        -quay-repository="{{ quay_repository }}}" \
        -verbosity="${VERBOSITY}" \
        -pull-policy="{{ pull_policy }}" \
        -namespace="{{ cdi_namespace }}"
    ) 1>>"${targetDir}/"$manifestNamej2

    # Remove empty lines at the end of files which are added by go templating
    find ${targetDir}/ -type f -exec sed -i {} -e '${/^$/d;}' \;
}

function processDirTemplates {
    inTmplPath=$1           #Path to directory from which to take manifests templates for processing
    outFinalManifestPath=$2 #Path to which to store final manifests version
    outTmplPath=$3          #Path to which to store templated manifests version
    generator=$4            #generator binary
    genManifestsDir=$5      #path where manifests generated from code are stored

    rm -rf $outFinalManifestPath
    rm -rf $outTmplPath
    mkdir -p $outFinalManifestPath
    mkdir -p $outTmplPath

    templates="$(find "${inTmplPath}" -maxdepth 1 -name "*.in"  -type f)"
    for tmpl in ${templates}; do
        tmpl=$(readlink -f "${tmpl}")
        populateResourceManifest  $generator $outFinalManifestPath $outTmplPath $tmpl $genManifestsDir $outFinalManifestPath
    done
}


# all templated final manifsets are located in _out/manifests/
# all templated  manifsets are located in _out/manifests/templates
function populateResourceManifest {    
    generator=$1
    targetDir=$2
    tmplTargetDir=$3
    tmpl=$4
    generatedManifests=$5    
    outDir=$6

    bundleOut="none"
    tmplBundleOut="none"
    outfile=$(basename -s .in "${tmpl}")

    if [[ $tmpl == *"VERSION"* ]]; then
        #if the processed template is CSV - pass output directory for olm bundle
        outfile=${outfile/VERSION/${CSV_VERSION}}
        bundleOut="${outDir}"
        tmplBundleOut="${tmplTargetDir}"
    fi
    (${generator} -template="${tmpl}" \
        -docker-repo="${DOCKER_PREFIX}" \
        -docker-tag="${DOCKER_TAG}" \
        -deploy-cluster-resources="true" \
        -operator-image="${OPERATOR_IMAGE_NAME}" \
        -controller-image="${CONTROLLER_IMAGE_NAME}" \
        -importer-image="${IMPORTER_IMAGE_NAME}" \
        -cloner-image="${CLONER_IMAGE_NAME}" \
        -apiserver-image="${APISERVER_IMAGE_NAME}" \
        -uploadproxy-image="${UPLOADPROXY_IMAGE_NAME}" \
        -uploadserver-image="${UPLOADSERVER_IMAGE_NAME}" \
        -csv-version="${CSV_VERSION}" \
        -cdi-logo-path="${CDI_LOGO_PATH}" \
        -generated-manifests-path=${generatedManifests} \
        -quay-namespace="${QUAY_NAMESPACE}" \
        -quay-repository="${QUAY_REPOSITORY}" \
        -verbosity="${VERBOSITY}" \
        -pull-policy="${PULL_POLICY}" \
        -namespace="${NAMESPACE}" \
        -olm-bundle-dir="${bundleOut}" \        
    ) 1>>"${targetDir}/"$outfile

    (${generator} -template="${tmpl}" \
        -docker-repo="{{ docker_prefix }}" \
        -docker-tag="{{ docker_tag }}" \
        -deploy-cluster-resources="true" \
        -operator-image="{{ operator_image_name }}" \
        -controller-image="{{ controller_image }}" \
        -importer-image="{{ importer_image }}" \
        -cloner-image="{{ cloner_image }}" \
        -apiserver-image="{{ apiserver_image }}" \
        -uploadproxy-image="{{ uploadproxy_image }}" \
        -uploadserver-image="{{ uploadserver_image }}" \
        -csv-version="${CSV_VERSION}" \
        -cdi-logo-path="${CDI_LOGO_PATH}" \
        -generated-manifests-path=${generatedManifests} \
        -quay-namespace="{{ quay_namespace }}" \
        -quay-namespace="{{ quay_repository }}" \
        -verbosity="${VERBOSITY}" \
        -pull-policy="{{ pull_policy }}" \
        -namespace="{{ cdi_namespace }}" \
        -olm-bundle-dir="${tmplBundleOut}" \
    ) 1>>"${tmplTargetDir}/"$outfile".j2"

    # Remove empty lines at the end of files which are added by go templating
    find ${targetDir}/ -type f -exec sed -i {} -e '${/^$/d;}' \;
    find ${tmplTargetDir}/ -type f -exec sed -i {} -e '${/^$/d;}' \;
}



