public with sharing class TicketController {

    @AuraEnabled(cacheable=true)
    public static List<Support_Ticket__c> getOpenTickets() {
        try {
            List<Support_Ticket__c> tickets = [
                SELECT Id, Name, Subject__c, Description__c, Priority__c, Status__c, CreatedDate
                FROM Support_Ticket__c
                WHERE Status__c != 'Closed'
                WITH USER_MODE
                ORDER BY CreatedDate ASC
            ];

            tickets.sort(new PriorityComparator());
            return tickets;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving tickets: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void closeTicket(Id ticketId) {
        try {
            Support_Ticket__c ticket = new Support_Ticket__c(
                Id = ticketId,
                Status__c = 'Closed'
            );
            update as user ticket;
        } catch (Exception e) {
            throw new AuraHandledException('Could not close the ticket: ' + e.getMessage());
        }
    }

    // Sorts tickets by real business urgency (High > Medium > Low),
    // not by the picklist's alphabetical order.
    // Ties on priority are broken by CreatedDate, oldest first.
    private class PriorityComparator implements Comparator<Support_Ticket__c> {
        public Integer compare(Support_Ticket__c t1, Support_Ticket__c t2) {
            Integer rank1 = getPriorityRank(t1.Priority__c);
            Integer rank2 = getPriorityRank(t2.Priority__c);

            if (rank1 != rank2) {
                return rank1 - rank2;
            }
            if (t1.CreatedDate < t2.CreatedDate) return -1;
            if (t1.CreatedDate > t2.CreatedDate) return 1;
            return 0;
        }

        private Integer getPriorityRank(String priority) {
            if (priority == 'High') return 0;
            if (priority == 'Medium') return 1;
            if (priority == 'Low') return 2;
            return 3;
        }
    }
}