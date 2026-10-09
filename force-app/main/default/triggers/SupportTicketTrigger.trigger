trigger SupportTicketTrigger on Support_Ticket__c (before insert, before update) {
    SupportTicketTriggerHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}