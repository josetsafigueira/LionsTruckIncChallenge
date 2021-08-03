trigger OrderTrigger on Order (after insert, after update) {
    
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            OrderDomain.afterInsert(trigger.new);
        } else if (trigger.isUpdate) {
            OrderDomain.afterUpdate(trigger.old, trigger.new);
        }
        
    }
}