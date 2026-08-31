#!/usr/bin/env bash

set -euo pipefail

test_root=$(mktemp -d)
trap 'rm -rf -- "${test_root}"' EXIT

aws_id='aws-access-key-id-sentinel'
aws_secret='aws-secret-sentinel-value'
aws_session='aws-session-token-sentinel-value'
azure_account='azure-account-sentinel'
azure_secret='azure-secret-sentinel-value'
gcp_json='{"type":"service_account","private_key":"gcp-secret-sentinel-value"}'
gcp_sa=$(printf '%s' "${gcp_json}" | base64 | tr -d '\n')

assert_absent() {
  local file=$1
  local value=$2

  if grep -Fq -- "${value}" "${file}"; then
    echo >&2 "Credential value was exposed by a command"
    exit 1
  fi
}

stub_dir="${test_root}/bin"
mkdir -p "${stub_dir}"

cat > "${stub_dir}/provider_stub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

command_name=$(basename "$0")
case "${command_name}" in
  upload_aws|backup_and_upload_aws)
    [[ "${AWS_ACCESS_KEY_ID}" == "${EXPECTED_AWS_ID}" ]]
    [[ "${AWS_SECRET_ACCESS_KEY}" == "${EXPECTED_AWS_SECRET}" ]]
    if [[ -n "${AWS_SESSION_TOKEN:-}" ]]; then
      [[ "${AWS_SESSION_TOKEN}" == "${EXPECTED_AWS_SESSION}" ]]
    fi
    ;;
  upload_azure|backup_and_upload_azure)
    [[ "${AZURE_STORAGE_ACCOUNT}" == "${EXPECTED_AZURE_ACCOUNT}" ]]
    [[ "${AZURE_STORAGE_KEY}" == "${EXPECTED_AZURE_SECRET}" ]]
    ;;
  upload_gcp)
    credential_file=$1
    [[ -f "${credential_file}" ]]
    [[ "$(cat "${credential_file}")" == "${EXPECTED_GCP_JSON}" ]]
    ;;
  backup_and_upload_gcp)
    credential_file=$5
    [[ -f "${credential_file}" ]]
    [[ "$(cat "${credential_file}")" == "${EXPECTED_GCP_JSON}" ]]
    ;;
esac

for argument in "$@"; do
  [[ "${argument}" != "${EXPECTED_AWS_ID}" ]]
  [[ "${argument}" != "${EXPECTED_AWS_SECRET}" ]]
  [[ "${argument}" != "${EXPECTED_AWS_SESSION}" ]]
  [[ "${argument}" != "${EXPECTED_AZURE_ACCOUNT}" ]]
  [[ "${argument}" != "${EXPECTED_AZURE_SECRET}" ]]
  [[ "${argument}" != "${EXPECTED_GCP_JSON}" ]]
  [[ "${argument}" != "${EXPECTED_GCP_SA}" ]]
done
EOF
chmod +x "${stub_dir}/provider_stub"

for command_name in \
  upload_aws backup_and_upload_aws \
  upload_gcp backup_and_upload_gcp \
  upload_azure backup_and_upload_azure; do
  ln -s provider_stub "${stub_dir}/${command_name}"
done

export PATH="${stub_dir}:${PWD}/bin:${PATH}"
export DEBUG=1
export EXPECTED_AWS_ID="${aws_id}"
export EXPECTED_AWS_SECRET="${aws_secret}"
export EXPECTED_AWS_SESSION="${aws_session}"
export EXPECTED_AZURE_ACCOUNT="${azure_account}"
export EXPECTED_AZURE_SECRET="${azure_secret}"
export EXPECTED_GCP_JSON="${gcp_json}"
export EXPECTED_GCP_SA="${gcp_sa}"

output_file="${test_root}/output"
touch "${test_root}/archive"

AWS_ACCESS_KEY_ID="${aws_id}" AWS_SECRET_ACCESS_KEY="${aws_secret}" AWS_SESSION_TOKEN="${aws_session}" \
  make --no-print-directory -f bin/actions.mk upload provider=aws \
    filepath="${test_root}/archive" bucket=bucket destination=destination \
    content_disposition="attachment; filename=test.tar" region=us-east-1 >"${output_file}" 2>&1
AWS_ACCESS_KEY_ID="${aws_id}" AWS_SECRET_ACCESS_KEY="${aws_secret}" AWS_SESSION_TOKEN="${aws_session}" \
  make --no-print-directory -f bin/actions.mk backup-and-upload provider=aws \
    dir="${test_root}" bucket=bucket destination=destination region=us-east-1 >>"${output_file}" 2>&1
AZURE_STORAGE_ACCOUNT="${azure_account}" AZURE_STORAGE_KEY="${azure_secret}" \
  make --no-print-directory -f bin/actions.mk upload provider=azure \
    filepath="${test_root}/archive" bucket=container destination=destination >>"${output_file}" 2>&1
AZURE_STORAGE_ACCOUNT="${azure_account}" AZURE_STORAGE_KEY="${azure_secret}" \
  make --no-print-directory -f bin/actions.mk backup-and-upload provider=azure \
    dir="${test_root}" bucket=container destination=destination >>"${output_file}" 2>&1
GCP_SA="${gcp_sa}" \
  make --no-print-directory -f bin/actions.mk upload provider=gcp \
    filepath="${test_root}/archive" bucket=bucket destination=destination >>"${output_file}" 2>&1
GCP_SA="${gcp_sa}" \
  make --no-print-directory -f bin/actions.mk backup-and-upload provider=gcp \
    dir="${test_root}" bucket=bucket destination=destination >>"${output_file}" 2>&1

# Keep the legacy make arguments working without echoing their values. They are
# intentionally not used by CI because process arguments are not secret-safe.
env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY -u AWS_SESSION_TOKEN \
  make --no-print-directory -f bin/actions.mk upload provider=aws \
    key="${aws_id}" secret="${aws_secret}" \
    filepath="${test_root}/archive" bucket=bucket destination=destination >>"${output_file}" 2>&1
env -u AZURE_STORAGE_ACCOUNT -u AZURE_STORAGE_KEY \
  make --no-print-directory -f bin/actions.mk upload provider=azure \
    key="${azure_account}" secret="${azure_secret}" \
    filepath="${test_root}/archive" bucket=container destination=destination >>"${output_file}" 2>&1
env -u GCP_SA -u GOOGLE_APPLICATION_CREDENTIALS \
  make --no-print-directory -f bin/actions.mk upload provider=gcp \
    key="${gcp_sa}" filepath="${test_root}/archive" bucket=bucket destination=destination >>"${output_file}" 2>&1

docker_args="${test_root}/docker-args"
cat > "${stub_dir}/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "${DOCKER_ARGS_FILE}"
EOF
chmod +x "${stub_dir}/docker"

DOCKER_ARGS_FILE="${docker_args}" \
BACKUP_TEST_TMP_DIR="${test_root}/backup-tests" \
IMAGE=test-image \
AWS_ACCESS_KEY_ID="${aws_id}" \
AWS_SECRET_ACCESS_KEY="${aws_secret}" \
AWS_SESSION_TOKEN="${aws_session}" \
AWS_REGION=us-east-1 \
GCP_SA="${gcp_sa}" \
AZURE_BLOB_CONTAINER=test-container \
AZURE_STORAGE_ACCOUNT="${azure_account}" \
AZURE_STORAGE_KEY="${azure_secret}" \
AZURE_STORAGE_ENDPOINT=https://example.invalid \
  ./test.sh >>"${output_file}" 2>&1

for value in \
  "${aws_id}" "${aws_secret}" "${aws_session}" \
  "${azure_account}" "${azure_secret}" \
  "${gcp_json}" "${gcp_sa}"; do
  assert_absent "${output_file}" "${value}"
  assert_absent "${docker_args}" "${value}"
done

for variable_name in \
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN GCP_SA \
  AZURE_STORAGE_ACCOUNT AZURE_STORAGE_KEY; do
  grep -Fxq -- "${variable_name}" "${docker_args}"
done
