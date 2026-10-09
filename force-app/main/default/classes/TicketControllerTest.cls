@isTest
private class TicketControllerTest {

    @isTest
    static void getOpenTicketsReturnsOnlyOpen() {
        insert new Support_Ticket__c(Subject__c = 'Open one', Status__c = 'New', Priority__c = 'Low');
        insert new Support_Ticket__c(Subject__c = 'Closed one', Status__c = 'Closed', Priority__c = 'Low');

        Test.startTest();
        List<Support_Ticket__c> results = TicketController.getOpenTickets();
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should only return the open ticket, the closed one must be excluded');
    }

    @isTest
    static void getOpenTicketsOrdersByPriorityCorrectly() {
        insert new Support_Ticket__c(Subject__c = 'Low one', Status__c = 'New', Priority__c = 'Low');
        insert new Support_Ticket__c(Subject__c = 'High one', Status__c = 'In Progress', Priority__c = 'High');
        insert new Support_Ticket__c(Subject__c = 'Medium one', Status__c = 'New', Priority__c = 'Medium');

        Test.startTest();
        List<Support_Ticket__c> results = TicketController.getOpenTickets();
        Test.stopTest();

        Assert.areEqual('High', results[0].Priority__c, 'First ticket should be High priority');
        Assert.areEqual('Medium', results[1].Priority__c, 'Second ticket should be Medium priority');
        Assert.areEqual('Low', results[2].Priority__c, 'Third ticket should be Low priority');
    }

    @isTest
    static void getOpenTicketsBulk() {
        List<Support_Ticket__c> bulkTickets = new List<Support_Ticket__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkTickets.add(new Support_Ticket__c(
                Subject__c = 'Bulk ticket ' + i,
                Priority__c = 'Medium'
            ));
        }
        insert bulkTickets;

        Test.startTest();
        List<Support_Ticket__c> results = TicketController.getOpenTickets();
        Test.stopTest();

        Assert.areEqual(200, results.size(), 'Should handle 200 open tickets without errors');
    }

    @isTest
    static void closeTicketUpdatesStatus() {
        Support_Ticket__c ticket = new Support_Ticket__c(Subject__c = 'Needs closing', Priority__c = 'Low');
        insert ticket;

        Test.startTest();
        TicketController.closeTicket(ticket.Id);
        Test.stopTest();

        Support_Ticket__c updatedTicket = [SELECT Status__c FROM Support_Ticket__c WHERE Id = :ticket.Id];
        Assert.areEqual('Closed', updatedTicket.Status__c, 'Ticket status should be updated to Closed');
    }

    @isTest
    static void closeTicketThrowsExceptionForInvalidId() {
        Support_Ticket__c ticket = new Support_Ticket__c(Subject__c = 'To be deleted', Priority__c = 'Low');
        insert ticket;
        Id deletedId = ticket.Id;
        delete ticket;

        Test.startTest();
        try {
            TicketController.closeTicket(deletedId);
            Assert.fail('Expected an AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            Assert.isTrue(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }
}