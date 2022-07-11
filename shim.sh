declare -g PL_TOOL_AZ_INSTALL_SCRIPT='https://aka.ms/InstallAzureCLIDeb'

declare -g PL_AZURE_TENANT=385bd7ec-08a1-4afd-8539-1b73531c8f98
declare -g PL_AZURE_SUBSCRIPTION=2a70945f-013c-4283-bc06-e96f5f04d689

declare -g PL_PREFIX=kingces95-core
declare -g PL_GROUP=rg
declare -g PL_LOCATION=eastus
declare -g PL_VNET=vnet
declare -g PL_VNET_ADDRESS_PREFIXES=10.0.0.0/16
declare -g PL_SUBNET=backend
declare -g PL_SUBNET_PREFIXES=10.0.0.0/24
declare -g PL_BASTION_SUBNET=AzureBastionSubnet
declare -g PL_BASTION_SUBNET_PREFIXES=10.0.1.0/27
declare -g PL_BASTION_IP=bastion
declare -g PL_BASTION=bastion
declare -g PL_WEBAPP=kingces95-web-app
declare -g PL_PLAN=kingces95-hosting-plan
declare -g PL_CONNECTION=connection
declare -g PL_PRIVATE_ENDPOINT=private-endpoint

declare -g PL_PRIVATE_DNS_ZONE='privatelink.azurewebsites.net'
declare -g PL_PRIVATE_DNS_ZONE_LINK='MyDNSLink'
declare -g PL_PRIVATE_DNS_ZONE_GROUP='MyZoneGroup'
declare -g PL_VM='my-vm'
declare -g PL_VM_USER='azureuser'
declare -g PL_VM_PASSWORD='Password123!'

pl::tool::az::install() (
    curl -sL "${PL_TOOL_AZ_INSTALL_SCRIPT}" \
        | sudo bash

    # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
    apt-cache policy azure-cli
    sudo apt-get install azure-cli=2.36.0-1~focal
)

pl::private_link() {
    # https://docs.microsoft.com/en-us/azure/private-link/create-private-endpoint-cli
    # https://dev.azure.com/devdiv/OnlineServices/_sprints/taskboard/Azure%20Lab%20Services%20-%20Fidalgo/OnlineServices/Copper/CY22%20Q3/2Wk/2Wk1?workitem=1567417

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

# Create a private endpoint

    local ID
    ID=$(az webapp list \
        --resource-group "${PL_GROUP}" \
        --query '[].[id]' \
        --output tsv)

    az network private-endpoint create \
        --connection-name "${PL_CONNECTION}" \
        --name "${PL_PRIVATE_ENDPOINT}" \
        --private-connection-resource-id "${ID}" \
        --resource-group "${PL_GROUP}" \
        --subnet "${PL_SUBNET}" \
        --group-id sites \
        --vnet-name "${PL_VNET}"  

# Register private link with DNS

    # DNS Name
    az network private-dns zone create \
        --resource-group "${PL_GROUP}" \
        --name "${PL_PRIVATE_DNS_ZONE}"

    # DNS Name <-> VNet
    az network private-dns link vnet create \
        --resource-group "${PL_GROUP}" \
        --zone-name "${PL_PRIVATE_DNS_ZONE}" \
        --name "${PL_PRIVATE_DNS_ZONE_LINK}" \
        --virtual-network "${PL_VNET}" \
        --registration-enabled false

    # DNS Name <-> Private Link
    az network private-endpoint dns-zone-group create \
        --resource-group "${PL_GROUP}" \
        --endpoint-name "${PL_PRIVATE_ENDPOINT}" \
        --name "${PL_PRIVATE_DNS_ZONE_GROUP}" \
        --private-dns-zone "${PL_PRIVATE_DNS_ZONE}" \
        --zone-name webapp

# Create a VM to browse to our website

    az vm create \
        --resource-group "${PL_GROUP}" \
        --name "${PL_VM}" \
        --image 'Win2019Datacenter' \
        --public-ip-address "" \
        --vnet-name "${PL_VNET}" \
        --subnet "${PL_SUBNET}" \
        --admin-username "${PL_VM_USER}" \
        --admin-password "${PL_VM_PASSWORD}"        
}
