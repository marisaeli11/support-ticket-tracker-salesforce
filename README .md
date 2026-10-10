# Support Ticket Tracker (Salesforce)

An internal support ticket system for a fictional company, **Pure Truth Water Factory (PTWF)**, built with code on the Salesforce platform: Apex Trigger, Handler class, Apex Controller, Lightning Web Component (LWC) and test classes.

Final project of the **Africa Ohana Developer Sprint** (intermediate Developer level).

Author: **Marisa Roberts**

---

## The problem

PTWF produces and distributes bottled water. Before this project, plant incidents (for example, a broken bottle-sealing machine) were reported through WhatsApp and in the hallway. Nobody could see what was urgent, and nobody recorded when an issue was solved.

## The solution

One place for every incident.

- Any employee can report a ticket.
- If the priority is **High**, the system moves the ticket to **In Progress** by itself.
- The ticket manager sees all open tickets on one dashboard, most urgent first, and closes each ticket with one click.
- A closed ticket gets a **Closed Date** automatically. It cannot be reopened.
- The priority of a ticket cannot be lowered.

## Users

| User | Role | What they do |
|---|---|---|
| Angela James | Plant Supervisor, Ticket Creator | Reports tickets. Cannot edit Status or Closed Date. |
| Lewis Webb | Finance Officer, Ticket Manager | Sees the dashboard and closes tickets. |

## Architecture

```
Permission Sets -> Record pages / LWC dashboard -> TicketController (Apex)
                                                        |
Save of a Support Ticket -> Trigger -> Handler -> Validation Rules -> Support_Ticket__c
```

| Piece | File | What it does |
|---|---|---|
| Trigger | `SupportTicketTrigger` | Runs before insert and before update. It only calls the Handler. |
| Handler | `SupportTicketTriggerHandler` | Escalates High priority tickets to In Progress and stamps `Closed_Date__c` when a ticket is Closed. |
| Controller | `TicketController` | `getOpenTickets()` returns open tickets, sorted by urgency. `closeTicket()` closes a ticket. |
| LWC | `ticketDashboard` | Dashboard with a data table and a **Close Ticket** button on each row. |
| Tests | `SupportTicketTriggerTest`, `TicketControllerTest` | 9 tests, including bulk tests with 200 records. |

## Design decisions

- **Trigger and Handler are separate.** The Trigger decides *when* the code runs. The Handler decides *what* it does. The Handler is a normal class, so it is easier to test and to change.
- **Before trigger.** The Handler changes fields on the same record before it is saved, so no extra DML is needed.
- **Bulk-safe.** The Handler works with lists. There are no queries and no DML inside loops, so it works the same with 1 record or 200.
- **Sorting with a Comparator.** The dashboard order is a business rule: High, Medium, Low, and then the oldest ticket first. It is written in an Apex `Comparator`, so it is explicit and tested.
- **Security.** The Controller uses `with sharing`, `WITH USER_MODE` and `update as user`, so it respects the user's records and field permissions.
- **`@wire` to read, direct call to change data.** The dashboard loads tickets with `@wire(getOpenTickets)`. Closing a ticket changes data, so `closeTicket` runs only when the user clicks the button, followed by `refreshApex`.
- **Validation Rules for restrictions.** `Prevent_Priority_Downgrade` and `Prevent_Reopen_Closed_Ticket` only block a save, so they are declarative. A Validation Rule cannot change a field value, so the Trigger does the automatic changes.
- **Field History Tracking** is enabled on Closed Date, Description, Priority, Status and Subject, to keep an audit trail.

## Tests and code coverage

| Item | Result |
|---|---|
| Tests passed | 9 of 9 |
| Org-wide coverage | 92% (Salesforce requires 75%) |
| `SupportTicketTrigger` | 100% |
| `SupportTicketTriggerHandler` | 100% |
| `TicketController` | 89% |

The lines not covered in the Controller are safety nets: an error handler for the query and a default value in the Comparator.

## What is in this repository

This repository contains the project in Salesforce DX format (`force-app/main/default`):

| Folder | Content |
|---|---|
| `classes` | Handler, Controller and the two test classes |
| `triggers` | `SupportTicketTrigger` |
| `lwc` | `ticketDashboard` component |
| `objects/Support_Ticket__c` | The custom object, its fields and the two Validation Rules |
| `permissionsets` | `Support_Ticket_Creator` and `Support_Ticket_Manager` |

Some configuration was done directly in the Salesforce Org and is not included here: the page layout, Field History Tracking and the user setup. It is described in the technical report.

## Future improvements

Ideas to grow the solution. They are not part of this version. They match section 10 of the technical report.

- **Closed Date on creation and in data imports.** The Handler stamps `Closed_Date__c` on insert and on update when the status is Closed and the date is empty, so a historical date that comes with an import is kept. This is verified manually, but not by an automated test. The proposal is to add tests for both cases and to validate them with a real import.
- **Security tests with `System.runAs`.** The tests run as an administrator, so `WITH USER_MODE` never rejects anything in them. The proposal is to run tests as users with each Permission Set: the Manager can query and close, the Creator cannot close, and a user without permissions gets a controlled error.
- **Email notification for the ticket manager.** Send an email when a High priority ticket is created. It needs an after trigger (or an asynchronous process), because the ticket must exist first, and it must stay bulk-safe: one email message for the whole list of tickets.
- **Filter the dashboard by priority and status.** The manager could focus only on the urgent tickets. It can be done in the LWC with the data the Controller already returns.
- **Summary of open tickets.** Show how many tickets are open by priority and status, using a grouped query in the Controller or a standard Salesforce Dashboard.
- **Jest tests for the LWC.** The dashboard is validated manually and through the Apex tests. Jest tests would mock the wire adapter and the Close Ticket action.

## Alternative evaluated

A formula field `Priority_Rank__c` (High 1, Medium 2, Low 3) would allow ordering in the query and remove the Comparator from Apex. It was not adopted: it adds a seventh field, needs extra field permissions in both Permission Sets, and the Comparator is already tested. It remains a valid option if the sorting is needed in reports.
