public with sharing class SyncAssetDataController {
    
    @AuraEnabled
    public static void syncWorkshopData(String vin, Id assetId){
        try {
            System.debug('HERE!');
            if (String.IsNotBlank(vin)) {
                String endpoint = String.format(RestConstants.clientSecrets.endpoint, new String[]{vin});
                Map<String, String> headersMap = new Map<String, String> {
                    'client-id' => RestConstants.clientSecrets.clientId,
                    'client-secret' => RestConstants.clientSecrets.clientSecret,
                    'correlation-id' => RestConstants.clientSecrets.correlationId
                };
               
                HttpResponse res = RestService.restCallout(RestService.HttpMethod.GET, headersMap, endpoint);

                if (res.getStatusCode() == 200) {
                    System.debug(res.getBody());
                    SchemaWorkShopAsset workShopAsset = SchemaWorkShopAsset.parseResult(res.getBody());
                    AssetService.newInstance().syncAssetDataWithWorkshop(assetId, workShopAsset);
                    System.debug(workShopAsset);
                }
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}
