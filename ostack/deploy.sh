#!/usr/bin/env bash
# Set color variable
CYAN='\033[1;36m'
NC='\033[0m' # No Color

set -e
# Provisions a virtual machine instance

# Local variables
export APP="${PORTAL_APP_REPO_FOLDER}"
echo "export APP=${APP}"

export TF_VAR_deployment_path="${PORTAL_DEPLOYMENTS_ROOT}/${PORTAL_DEPLOYMENT_REFERENCE}"
echo "export TF_VAR_deployment_path=${TF_VAR_deployment_path}"

export DPL="${PORTAL_DEPLOYMENTS_ROOT}/${PORTAL_DEPLOYMENT_REFERENCE}/"
echo "export DPL=${DPL}"

export PRIV_KEY_PATH="${DPL}${PORTAL_DEPLOYMENT_REFERENCE}"
echo "export PRIV_KEY_PATH=${PRIV_KEY_PATH}"

# Export input variables in the bash environment
export TF_VAR_name="$(awk -v var="${PORTAL_DEPLOYMENT_REFERENCE}" 'BEGIN {print tolower(var)}')"
echo "export TF_VAR_name=${TF_VAR_name}"

export KEY_PATH="${DPL}${PORTAL_DEPLOYMENT_REFERENCE}.pub"
echo "export KEY_PATH=${KEY_PATH}"

export TF_VAR_key_path="${KEY_PATH}"
echo "export TF_VAR_key_path=${TF_VAR_key_path}"

export TF_STATE=${DPL}
echo "export TF_STATE=${TF_STATE}"

# Launch provisioning of the VM
echo -e "\n\t${CYAN}Terraform apply${NC}\n"
terraform -chdir=${APP}'/ostack/terraform' init
terraform -chdir=${APP}'/ostack/terraform' apply --state=${DPL}'terraform.tfstate'  -auto-approve

# Extract the external IP of the instance
external_ip=$(terraform output -state=${DPL}'terraform.tfstate' external_ip)

# Install Ansible requirements with ansible galaxy
echo -e "\n\t${CYAN}Install Ansible requirements with ansible galaxy${NC}\n"
cd ostack/ansible || exit
ansible-galaxy install -r requirements.yml

# Set default value for Ansible variables if they are either empty or undefined
export TF_VAR_remote_folder="${TF_VAR_remote_folder:-/var/nfs}"
echo "export TF_VAR_remote_folder=${TF_VAR_remote_folder}"
export TF_VAR_local_folder="${TF_VAR_local_folder:-/nfs-imports}"
echo "export TF_VAR_local_folder=${TF_VAR_local_folder}"
export ANSIBLE_REMOTE_USER="${TF_VAR_remote_user:-ubuntu}"
echo "export ANSIBLE_REMOTE_USER=${ANSIBLE_REMOTE_USER}"

# Launch Ansible playbook
echo -e "\n\t${CYAN}Launch Ansible playbook${NC}\n"
ansible-playbook -b playbook.yml
