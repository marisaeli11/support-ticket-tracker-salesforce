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

This repository contains the **code**: Apex classes, the Trigger and the LWC (`force-app/main/default`).

The data model and configuration were created in the Salesforce Org and are not included here: the `Support_Ticket__c` object and its fields, the two Validation Rules, the Permission Sets, the page layout and Field History Tracking. They are described in the technical report.

## Future improvements

- Jest unit tests for the LWC, mocking the wire adapter and the Close Ticket action.
- Filter tickets by Contact.
- A dedicated Lightning app for the ticket manager.
