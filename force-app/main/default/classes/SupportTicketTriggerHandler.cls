public with sharing class SupportTicketTriggerHandler {

    public static void handleTrigger(
        List<Support_Ticket__c> newList,
        Map<Id, Support_Ticket__c> oldMap,
        System.TriggerOperation operationType
    ) {
        switch on operationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                autoEscalateHighPriority(newList);
                stampClosedDate(newList);
            }
        }
    }

    private static void autoEscalateHighPriority(List<Support_Ticket__c> tickets) {
        for (Support_Ticket__c ticket : tickets) {
            if (ticket.Priority__c == 'High' && ticket.Status__c == 'New') {
                ticket.Status__c = 'In Progress';
            }
        }
    }

    // Any closed ticket must carry a closing timestamp, whether it was closed
    // through an update or was created already closed (e.g. a data load).
    // An existing value is never overwritten, so historical dates are preserved.
    private static void stampClosedDate(List<Support_Ticket__c> tickets) {
        for (Support_Ticket__c ticket : tickets) {
            if (ticket.Status__c == 'Closed' && ticket.Closed_Date__c == null) {
                ticket.Closed_Date__c = System.now();
            }
        }
    }
}