#!/usr/bin/env bash
set -euo pipefail

: "${EIFFELSTUDIO_VERSION:?EIFFELSTUDIO_VERSION is required}"
: "${EIFFELSTUDIO_REVISION:?EIFFELSTUDIO_REVISION is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"

if [[ "${RUNNER_ARCH:-}" != "X64" ]]; then
    echo "Unsupported runner architecture: ${RUNNER_ARCH:-unknown}" >&2
    exit 1
fi

platform=linux-x86-64
archive_name="Eiffel_${EIFFELSTUDIO_VERSION}_rev_${EIFFELSTUDIO_REVISION}-${platform}.tar.bz2"
archive_url="https://www.eiffel.com/cdn/EiffelStudio/${EIFFELSTUDIO_VERSION}/${EIFFELSTUDIO_REVISION}/${archive_name}"
archive="${RUNNER_TEMP}/${archive_name}"
distribution="${RUNNER_TEMP}/eiffelstudio-distribution"
root="${distribution}/Eiffel_${EIFFELSTUDIO_VERSION}"
compiler="${root}/studio/spec/${platform}/bin/ec"

mkdir -p "${distribution}"
curl --fail --silent --show-error --location --output "${archive}" "${archive_url}"
tar -xjf "${archive}" -C "${distribution}"

if [[ ! -x "${compiler}" ]]; then
    echo "The EiffelStudio archive does not contain ${compiler}" >&2
    exit 1
fi

export ISE_EIFFEL="${root}"
export ISE_LIBRARY="${root}"
export ISE_PLATFORM="${platform}"
"${compiler}" -version

echo "ISE_EIFFEL=${ISE_EIFFEL}" >> "${GITHUB_ENV}"
echo "ISE_LIBRARY=${ISE_LIBRARY}" >> "${GITHUB_ENV}"
echo "ISE_PLATFORM=${ISE_PLATFORM}" >> "${GITHUB_ENV}"
echo "${root}/studio/spec/${platform}/bin" >> "${GITHUB_PATH}"
