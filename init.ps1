$prefix = "demo"
az group create -l WestEurope -n "tfstate-$($prefix)-rg"
az storage account create -n "tfstatestore$($prefix)" -g "tfstate-$($prefix)-rg" -l WestEurope --sku Standard_LRS
az storage container create -n "tf-state" --account-name "tfstatestore$($prefix)" --public-access container