trigger QuoteLineItemTrigger on QuoteLineItem (after update, after delete) {

    if (trigger.isAfter) {
        if (trigger.isUpdate) {
            QuoteLineItemDomain.afterUpdate(trigger.old, trigger.new);
        } else if (trigger.isDelete) {
            QuoteLineItemDomain.afterDelete(trigger.old);
        }
    }
}