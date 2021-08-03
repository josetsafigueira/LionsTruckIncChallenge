public with sharing class AssetService {

    private Asset assetToSync;
    private List<WorkOrder> workOrdersToRegister;
    
    private AssetService() {
        this.assetToSync = new Asset();
        this.workOrdersToRegister = new List<WorkOrder>();
    }

    public static AssetService newInstance() {
        return new AssetService();
    }

    public void syncAssetDataWithWorkshop(Id assetId, SchemaWorkShopAsset externalAsset) {
        getAssetData(assetId);
        //validateAssetData(externalAsset); Needs to be commented due to the mocking api always returning the same vehicle
        populateAssetData(externalAsset);

        if (isNewMeasure(getRelatedWorkOrders(), externalAsset)) {
            generateWorkOrders(externalAsset);
        }

        update this.assetToSync;
        if (!this.workOrdersToRegister.isEmpty()) {
            insert this.workOrdersToRegister;
        }
    }

    private void getAssetData(Id assetId){
        List<Asset> assets = [SELECT Id, SerialNumber, AccountId FROM Asset WHERE Id = :assetId];
        this.assetToSync = assets.isEmpty() ? new Asset(Id = null) : assets[0];
    }

    private void validateAssetData(SchemaWorkShopAsset externalAsset) {
        if (String.isBlank(this.assetToSync.Id)) {
            throw new AssetServiceException('No Asset was found');
        } else if (this.assetToSync.SerialNumber != externalAsset.vin) {
            throw new AssetServiceException('The Asset Serial Number does not match the workshop VIN');
        }   
    }

    private void populateAssetData(SchemaWorkShopAsset externalAsset) {
        this.assetToSync.Vehicle_Number__c = externalAsset.vehicleNum;
        this.assetToSync.Vehicle_Type__c = externalAsset.vehicleType;
        this.assetToSync.Model_Range__c = externalAsset.modelRange;
        this.assetToSync.Type_Variant__c = externalAsset.typeVariant;
        this.assetToSync.Suspension__c = externalAsset.suspension;
        this.assetToSync.Region_Number__c = externalAsset.vehicleRegNum;
        this.assetToSync.Region_Country_Key__c = externalAsset.regNumCountryKey;
    }

    private List<WorkOrder> getRelatedWorkOrders() {
        return [SELECT Id, AccountId, Counter_Reading__c, Measuring_Point_Unit__c FROM WorkOrder WHERE AssetId = :this.assetToSync.Id];
    }

    private Boolean isNewMeasure(List<WorkOrder> workOrders, SchemaWorkShopAsset externalAsset) {
        Boolean isNewMeasure = true;
        if (!workOrders.isEmpty()) {
            for (WorkOrder workO : workOrders) {
                if (workO.Counter_Reading__c == externalAsset.measuringPoint.counterReading) {
                    isNewMeasure = false;
                    break;
                }
            }
        }
        return isNewMeasure;
    }

    private void generateWorkOrders(SchemaWorkShopAsset externalAsset) {
        String description = '';
        WorkOrder newWorkOrder = new WorkOrder();
        newWorkOrder.AccountId = this.assetToSync.AccountId;
        newWorkOrder.AssetId = this.assetToSync.Id;
        newWorkOrder.Status = 'Completed';
        newWorkOrder.Counter_Reading__c = externalAsset.measuringPoint.counterReading;
        newWorkOrder.Measuring_Point_Unit__c = externalAsset.measuringPoint.mpUnit;
        newWorkOrder.Subject = externalAsset.vehicleTextData.informationText.textLine;

        if (!externalAsset.vehicleTextData.noteText.isEmpty()) {
            for (SchemaWorkShopAsset.VehicleNoteText textLines : externalAsset.vehicleTextData.noteText) {
                description += textLines.textLine + '\n';
            } 
        }
        newWorkOrder.Description = description;
        this.workOrdersToRegister.add(newWorkOrder);
    }

    public class AssetServiceException extends Exception {}
}
