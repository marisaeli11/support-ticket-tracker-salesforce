@isTest
private class SupportTicketTriggerTest {

    @isTest
    static void testSingleHighPriorityAutoEscalation() {
        Support_Ticket__c ticket = new Support_Ticket__c(
            Subject__c = 'Test high priority ticket',
            Priority__c = 'High',
            Status__c = 'New'
        );
        
        Test.startTest();
        insert ticket;
        Test.stopTest();

        Support_Ticket__c insertedTicket = [SELECT Status__c FROM Support_Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('In Progress', insertedTicket.Status__c, 'High priority ticket should automatically change to In Progress');
    }

    @isTest
    static void testBulkInsert200Tickets() {
        List<Support_Ticket__c> tickets = new List<Support_Ticket__c>();
        for (Integer i = 0; i < 200; i++) {
            tickets.add(new Support_Ticket__c(
                Subject__c = 'Bulk ticket ' + i,
                Priority__c = 'High',
                Status__c = 'New'
            ));
        }

        Test.startTest();
        insert tickets;
        Test.stopTest();

        List<Support_Ticket__c> insertedTickets = [SELECT Status__c FROM Support_Ticket__c WHERE Id IN :tickets];
        for (Support_Ticket__c t : insertedTickets) {
            Assert.areEqual('In Progress', t.Status__c, 'Each ticket in the bulk list should be In Progress');
        }
    }

    @isTest
    static void testLowPriorityDoesNotAutoEscalate() {
        Support_Ticket__c ticket = new Support_Ticket__c(
            Subject__c = 'Test low priority ticket',
            Priority__c = 'Low',
            Status__c = 'New'
        );

        Test.startTest();
        insert ticket;
        Test.stopTest();

        Support_Ticket__c insertedTicket = [SELECT Status__c FROM Support_Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('New', insertedTicket.Status__c, 'Low priority ticket should remain in New status');
    }

    @isTest
    static void testTicketLifecycleFromEscalationToClosure() {
        // Step 1: Create initial Medium priority ticket
        Support_Ticket__c ticket = new Support_Ticket__c(
            Subject__c = 'Test ticket lifecycle',
            Priority__c = 'Medium',
            Status__c = 'New'
        );
        insert ticket;

        Test.startTest();
        
        // Step 2: Escalate priority to High (triggers auto-escalation to In Progress)
        ticket.Priority__c = 'High';
        update ticket;

        Support_Ticket__c escalatedTicket = [SELECT Status__c FROM Support_Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('In Progress', escalatedTicket.Status__c, 'High priority ticket should auto-escalate to In Progress');

        // Step 3: Resolve and close ticket (triggers stampClosedDate)
        ticket.Status__c = 'Closed';
        update ticket;
        
        Test.stopTest();

        Support_Ticket__c closedTicket = [SELECT Status__c, Closed_Date__c FROM Support_Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('Closed', closedTicket.Status__c, 'Status should be Closed');
        Assert.areNotEqual(null, closedTicket.Closed_Date__c, 'Closed date should be populated when closing the ticket');
    }
}