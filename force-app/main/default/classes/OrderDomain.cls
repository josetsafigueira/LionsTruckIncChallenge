public with sharing class OrderDomain {
    
    public static void afterInsert(List<Order> newOrderList) {
        Map<Id, Order> quoteIdWithOrderMap = new Map<Id, Order>();
        Set<Id> quoteIds = new Set<Id>();
        List<OrderItem> orderItemsToCreate;
        
        for (Order newOrder : newOrderList) {
            if (String.IsNotBlank(newOrder.QuoteId)) {
                quoteIdWithOrderMap.put(newOrder.QuoteId, newOrder);
            }
        }
        orderItemsToCreate = generateOrderItems(quoteIdWithOrderMap);

        if(!orderItemsToCreate.isEmpty()) {
            insert orderItemsToCreate;
        }
    }

    public static void afterUpdate(List<Order> oldOrders, List<Order> updatedOrders) {
        Set<Id> invalidOrderIds;
        List<OrderItem> orderItems;
        List<Asset> assetsToCreate;
        Map<Id, Order> ordersInActivation = new Map<Id, Order>();
        Map<Id, Order> oldOrdersMap = new Map<Id, Order>(oldOrders);
        Id truckProductRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Vehicle').getRecordTypeId();

        for (Order updatedOrder : updatedOrders) {
            if (oldOrdersMap.get(updatedOrder.Id).Status != 'Activated' && updatedOrder.Status == 'Activated') {
                ordersInActivation.put(updatedOrder.Id, updatedOrder);
            }
        }
        orderItems = getOrderItemsByOrder(ordersInActivation.keySet());
        invalidOrderIds = getInvalidOrdersForActivation(orderItems, truckProductRecordTypeId);

        if (!invalidOrderIds.isEmpty()) {
            for(Id invalidOrderId : invalidOrderIds) {
                ordersInActivation.get(invalidOrderId).addError('An order cannot be activated until all vehicles have a serial number');
                ordersInActivation.remove(invalidOrderId);
            }
        }
        assetsToCreate = generateAssets(ordersInActivation, orderItems, truckProductRecordTypeId);

        if (!assetsToCreate.isEmpty()) {
            insert assetsToCreate;
        }
    }

    private static List<Asset> generateAssets(Map<Id, Order> ordersToActivate, List<OrderItem> orderItemsDelivered, Id truckProductRecordTypeId) {
        List<Asset> assetsToInsert = new List<Asset>();

        for (OrderItem orderItemToConvert : orderItemsDelivered) {
            if (ordersToActivate.keySet().contains(orderItemToConvert.OrderId) && truckProductRecordTypeId == orderItemToConvert.Product2.RecordTypeId) {
                Asset newAsset = new Asset();
                newAsset.AccountId = ordersToActivate.get(orderItemToConvert.OrderId).AccountId;
                newAsset.Name = orderItemToConvert.Product2.Name;
                newAsset.Product2Id = orderItemToConvert.Product2Id;
                newAsset.SerialNumber = orderItemToConvert.Truck_Serial_Number__c;
                newAsset.InstallDate = Date.valueOf(ordersToActivate.get(orderItemToConvert.OrderId).ActivatedDate);
                newAsset.Quantity = orderItemToConvert.Quantity;
                newAsset.Status = 'Installed';
                newAsset.Price = orderItemToConvert.TotalPrice;
                assetsToInsert.add(newAsset);
            }
        }

        return assetsToInsert;
    }

    private static List<OrderItem> getOrderItemsByOrder(Set<Id> orderIds) {
        return [SELECT Id, Product2.Name, Product2Id, Truck_Serial_Number__c, OrderId, Quantity, TotalPrice, Product2.RecordTypeId FROM OrderItem WHERE OrderId IN :orderIds];
    }

    private static List<OrderItem> generateOrderItems(Map<Id, Order> quoteIdWithOrderMap) {
        List<OrderItem> orderItemsToCreate = new List<OrderItem>();
        Map<Id, QuoteLineItem> relatedQuoteLineItems = new Map<Id, QuoteLineItem>([SELECT Id, Product2Id, UnitPrice, Quantity, QuoteId, Parent_Quote_Line_Item__c, PricebookEntryId FROM QuoteLineItem WHERE QuoteId IN :quoteIdWithOrderMap.keySet()]);
        
        for(QuoteLineItem relatedQuoteLineItem : relatedQuoteLineItems.values()) {
            OrderItem orderProduct = new OrderItem();
            orderProduct.QuoteLineItemId = relatedQuoteLineItem.Id;
            orderProduct.OrderId = quoteIdWithOrderMap.get(relatedQuoteLineItem.QuoteId).Id;
            orderProduct.Product2Id = relatedQuoteLineItem.Product2Id;
            orderProduct.Quantity = 1;
            orderProduct.UnitPrice = relatedQuoteLineItem.UnitPrice;
            orderProduct.QuoteLineItemId = relatedQuoteLineItem.Id;
            orderProduct.PriceBookEntryId = relatedQuoteLineItem.PricebookEntryId;
            orderItemsToCreate.add(orderProduct);
            if (relatedQuoteLineItem.Quantity > 1) { //Needed to seperate products for Serial Number input
                for(Integer i = 1; i < relatedQuoteLineItem.Quantity; i++) {
                    OrderItem clonnedOrderProduct = orderProduct.clone(false, true, false, false);
                    orderItemsToCreate.add(clonnedOrderProduct);
                }
            }
        }

        return orderItemsToCreate;
    }

    private static Set<Id> getInvalidOrdersForActivation(List<OrderItem> orderItems, Id truckProductRecordTypeId) {
        Set<Id> invalidOrderItems = new Set<Id>();
        for (OrderItem oi : orderItems) {
            if (String.isBlank(oi.Truck_Serial_Number__c) && oi.Product2.RecordTypeId == truckProductRecordTypeId) {
                invalidOrderItems.add(oi.OrderId);
            }
        }
        return invalidOrderItems;
    }

    
}