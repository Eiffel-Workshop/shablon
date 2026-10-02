#!/usr/bin/env bash
set -euo pipefail

case "${RUNNER_ARCH}" in
    X64) architecture=x86_64 ;;
    ARM64) architecture=arm64 ;;
    *) echo "Unsupported runner architecture: ${RUNNER_ARCH}" >&2; exit 1 ;;
esac

case "${RUNNER_OS}" in
    Linux) platform=linux ;;
    macOS) platform=macos ;;
    *) echo "Unsupported runner OS: ${RUNNER_OS}" >&2; exit 1 ;;
esac

release_url="https://api.github.com/repos/gobo-eiffel/gobo/releases/tags/${GOBO_TAG}"
asset_prefix="gobo-${platform}-${architecture}-"
asset_url="$({ curl --fail --silent --show-error --location \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    "${release_url}"; } | jq --raw-output --arg prefix "${asset_prefix}" \
    '.assets[] | select((.name | startswith($prefix)) and (.name | endswith(".tar.xz"))) | .browser_download_url' | head -n 1)"

if [[ -z "${asset_url}" ]]; then
    echo "No Gobo asset found with prefix ${asset_prefix}" >&2
    exit 1
fi

archive="${RUNNER_TEMP}/gobo.tar.xz"
distribution="${RUNNER_TEMP}/gobo-distribution"
mkdir -p "${distribution}"
curl --fail --silent --show-error --location --output "${archive}" "${asset_url}"
tar -xJf "${archive}" -C "${distribution}"

gec_path="$(find "${distribution}" -type f -path '*/bin/gec' -print -quit)"
if [[ -z "${gec_path}" ]]; then
    echo "The Gobo archive does not contain bin/gec" >&2
    exit 1
fi

gobo_root="$(dirname "$(dirname "${gec_path}")")"
echo "GOBO=${gobo_root}" >> "${GITHUB_ENV}"
echo "${gobo_root}/bin" >> "${GITHUB_PATH}"
