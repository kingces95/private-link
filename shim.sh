declare -g PL_TOOL_AZ_INSTALL_SCRIPT='https://aka.ms/InstallAzureCLIDeb'

declare -g PL_AZURE_TENANT=385bd7ec-08a1-4afd-8539-1b73531c8f98
declare -g PL_AZURE_SUBSCRIPTION=2a70945f-013c-4283-bc06-e96f5f04d689

declare -g PL_PREFIX=kingces95-core
declare -g PL_GROUP="${PL_PREFIX}"-rg
declare -g PL_LOCATION=eastus
declare -g PL_VNET="${PL_PREFIX}"vnet
declare -g PL_VNET_ADDRESS_PREFIXES=10.0.0.0/16
declare -g PL_SUBNET=backend
declare -g PL_SUBNET_PREFIXES=10.0.0.0/24
declare -g PL_BASTION_SUBNET=AzureBastionSubnet
declare -g PL_BASTION_SUBNET_PREFIXES=10.0.1.0/27
declare -g PL_BASTION_IP="${PL_PREFIX}"-bastion-ip
declare -g PL_BASTION="${PL_PREFIX}"-bastion-host

pl::tool::az::install() (
    curl -sL "${PL_TOOL_AZ_INSTALL_SCRIPT}" \
        | sudo bash
)

pl::private_link() {
    # https://docs.microsoft.com/en-us/azure/private-link/create-private-endpoint-cli

    az login \
        --use-device-code \
        --tenant "${PL_AZURE_TENANT}"

    az account set \
        --subscription "${PL_AZURE_SUBSCRIPTION}"

    az group create \
        --name "${PL_GROUP}" \
        --location "${PL_LOCATION}"
        
    az network vnet create \
        --resource-group "${PL_GROUP}" \
        --location "${PL_LOCATION}" \
        --name "${PL_VNET}" \
        --address-prefixes "${PL_VNET_ADDRESS_PREFIXES}" \
        --subnet-name "${PL_SUBNET}" \
        --subnet-prefixes "${PL_SUBNET_PREFIXES}"

    az network vnet subnet create \
        --resource-group "${PL_GROUP}" \
        --name "${PL_BASTION_SUBNET}" \
        --vnet-name "${PL_VNET}" \
        --address-prefixes "${PL_BASTION_SUBNET_PREFIXES}"

    az network public-ip create \
        --resource-group "${PL_GROUP}" \
        --name "${PL_BASTION_IP}" \
        --sku Standard \
        --zone 1 2 3

    az network bastion create \
        --resource-group "${PL_GROUP}" \
        --name "${PL_BASTION}" \
        --public-ip-address "${PL_BASTION_IP}" \
        --vnet-name "${PL_VNET}" \
        --location "${PL_LOCATION}"

    # (InvalidResourceReference) Resource /subscriptions/2a70945f-013c-4283-bc06-e96f5f04d689
    # /resourceGroups/KINGCES95-CORE-RG
    # /providers/Microsoft.Network/publicIPAddresses/KINGCES95-CORE-BASTION-IP 
    # referenced by resource /subscriptions/2a70945f-013c-4283-bc06-e96f5f04d689
    # /resourceGroups/kingces95-core-rg
    # /providers/Microsoft.Network/bastionHosts/kingces95-core-bastion-host 
    # was not found. Please make sure that the referenced resource exists, 
    # and that both resources are in the same region.
}
