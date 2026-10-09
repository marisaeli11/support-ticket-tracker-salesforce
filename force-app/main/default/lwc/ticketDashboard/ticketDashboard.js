import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getOpenTickets from '@salesforce/apex/TicketController.getOpenTickets';
import closeTicket from '@salesforce/apex/TicketController.closeTicket';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    {
        label: 'Support Ticket Number',
        fieldName: 'Name',
        type: 'text'
    },
    {
        label: 'Subject',
        fieldName: 'RecordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Subject__c' },
            target: '_blank'
        }
    },
    { label: 'Priority', fieldName: 'Priority__c' },
    { label: 'Status', fieldName: 'Status__c' },
    {
        label: 'Created Date',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        type: 'button',
        typeAttributes: {
            label: 'Close Ticket',
            name: 'close_ticket',
            title: 'Close Ticket',
            disabled: false,
            value: 'close',
            variant: 'brand'
        }
    }
];

export default class TicketDashboard extends LightningElement {
    tickets = [];
    error;
    columns = columns;

    wiredTicketsResult;

    @wire(getOpenTickets)
    wiredTickets(result) {
        this.wiredTicketsResult = result;
        const { error, data } = result;
        if (data) {
            this.tickets = data.map(ticket => {
                return {
                    ...ticket,
                    RecordUrl: `/lightning/r/Support_Ticket__c/${ticket.Id}/view`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.tickets = [];
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'close_ticket') {
            closeTicket({ ticketId: row.Id })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `The ticket "${row.Subject__c}" has been closed.`,
                            variant: 'success',
                        })
                    );
                    return refreshApex(this.wiredTicketsResult);
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error closing ticket',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                });
        }
    }
}
