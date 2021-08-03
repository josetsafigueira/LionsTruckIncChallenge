public with sharing class QuoteLineItemDomain {
    
    public static void afterUpdate(List<QuoteLineItem> oldQLIList, List<QuoteLineItem> newQLIList) {
        Map<Id, QuoteLineItem> oldQuoteLineItems = new Map<Id, QuoteLineItem>(oldQLIList);
        Set<Id> parentQLIIdSet = new Set<Id>();
        Set<Id> subscriptionProductIdSet = new Set<Id>();
        List<QuoteLineItem> parentQLIList = new List<QuoteLineItem>();
        
        for(QuoteLineItem newQLI : newQLIList) {
            if (String.isBlank(newQLI.Parent_Quote_Line_Item__c)) {
                if (String.isNotBlank(newQLI.Service_Per_Truck_Product__c) && String.isBlank(oldQuoteLineItems.get(newQLI.Id).Service_Per_Truck_Product__c)) {
                    parentQLIList.add(newQLI);
    
                    if (!subscriptionProductIdSet.contains(newQLI.Service_Per_Truck_Product__c)) {
                        subscriptionProductIdSet.add(newQLI.Service_Per_Truck_Product__c);
                    }
    
                } else if (String.isBlank(newQLI.Service_Per_Truck_Product__c) && String.isNotBlank(oldQuoteLineItems.get(newQLI.Id).Service_Per_Truck_Product__c)) {
                    parentQLIIdSet.add(newQLI.Id);
    
                } else if (newQLI.Service_Per_Truck_Product__c != oldQuoteLineItems.get(newQLI.Id).Service_Per_Truck_Product__c) {
                    parentQLIIdSet.add(newQLI.Id);
                    parentQLIList.add(newQLI);
    
                    if (!subscriptionProductIdSet.contains(newQLI.Service_Per_Truck_Product__c)) {
                        subscriptionProductIdSet.add(newQLI.Service_Per_Truck_Product__c);
                    }
                }
            }
        }

        if (!parentQLIIdSet.isEmpty()) {
            deleteChildQLIs(parentQLIIdSet);
        }

        if (!parentQLIList.isEmpty()) {
            createSubscriptionChildQLIs(subscriptionProductIdSet, parentQLIList);
        }
    }

    public static void afterDelete(List<QuoteLineItem> oldQLIList) {
        Map<Id, QuoteLineItem> oldQLIMap = new Map<Id, QuoteLineItem>(oldQLIList);
        deleteChildQLIs(oldQLIMap.keySet());
    }

    private static void createSubscriptionChildQLIs(Set<Id> subscriptionProductIds, List<QuoteLineItem> parentQLIList) {
        List<QuoteLineItem> newQLIList = new List<QuoteLineItem>();
        Map<Id, PriceBookEntry> productPercentagePriceMap = getSubscriptionPriceBookEntries(subscriptionProductIds);

        for(QuoteLineItem parentQLI : parentQLIList) {
            PriceBookEntry pbe = productPercentagePriceMap.get(parentQLI.Service_Per_Truck_Product__c);
            QuoteLineItem newQLI = new QuoteLineItem();
            newQLI.QuoteId = parentQLI.QuoteId;
            newQLI.PriceBookEntryId = pbe.Id;
            newQLI.Quantity = parentQLI.Number_of_Subscriptions__c;
            newQLI.Parent_Quote_Line_Item__c = parentQLI.Id;
            newQLI.Product2Id = parentQLI.Service_Per_Truck_Product__c;
            newQLI.UnitPrice = parentQLI.UnitPrice * (pbe.Price_in_Percentage__c / 100) * parentQLI.Number_of_Subscriptions__c;
            newQLIList.add(newQLI);
        }

        if (!newQLIList.isEmpty()) {
            insert newQLIList;
        }
    }

    private static void deleteChildQLIs(Set<Id> parentQLIIdSet) {
        List<QuoteLineItem> qliToDelete = [SELECT Id FROM QuoteLineItem WHERE Parent_Quote_Line_Item__c IN :parentQLIIdSet];
        if (!qliToDelete.isEmpty()) {
            delete qliToDelete;
        }
    }

    private static Map<Id, PriceBookEntry> getSubscriptionPriceBookEntries(Set<Id> productIds) {
        Map<Id, PriceBookEntry> percentageValueMap = new Map<Id, PriceBookEntry>();
        List<PriceBookEntry> pbeList = [SELECT Id, Price_in_Percentage__c, Product2Id FROM PriceBookEntry WHERE Product2Id IN :productIds AND IsActive = true AND PriceBook2.Name = 'LionsTruckPriceBook'];

        if (!pbeList.isEmpty()) {
            for (PriceBookEntry pbe : pbeList) {
                if (!percentageValueMap.keySet().contains(pbe.Product2Id)){
                    percentageValueMap.put(pbe.Product2Id, pbe);
                }
            }
        }

        return percentageValueMap;
    }
}
