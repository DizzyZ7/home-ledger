# Product brief — HomeLedger

## Tagline

**Know what you own. Never miss maintenance.**

## Problem statement

People own appliances, tools, devices, and other household equipment that come with warranties, receipts, serial numbers, and service requirements. This information is frequently spread across paper folders, photo libraries, emails, and memory. As a result, warranties expire unnoticed and simple maintenance is missed.

## Target audience

- Renters and homeowners who manage several appliances or devices.
- Couples and families who need a shared, understandable household inventory.
- Privacy-minded users who prefer self-hosted software to a mandatory vendor cloud.

## Value proposition

HomeLedger offers a calm, local-first place to find what an item is, where it is stored, whether it is still under warranty, and what should be done next.

## MVP scope

1. Authenticated household owner account.
2. One default household created during registration.
3. Items with category, location, serial number, purchase date, warranty expiration, and notes.
4. Recurring maintenance tasks tied to an item.
5. Dashboard summary for expiring warranties and overdue maintenance.
6. RU/EN localization, light/dark mode, error states, local cache, and mock mode.
7. Dockerized REST API with PostgreSQL, migrations, seed data, tests, and OpenAPI docs.

## Post-MVP

- Invitations and household roles.
- Receipt and photo attachments via local S3-compatible storage.
- Push notifications and platform widgets.
- Encrypted exports and imports.
- CSV import from spreadsheets.
- Optional smart extraction of item metadata from user-provided receipts, behind an explicit local or remote provider choice.

## Core user scenarios

### Add an appliance

A user opens the dashboard, taps **Add item**, enters a washing machine name, purchase date and warranty end date, then saves it. The item appears immediately, even in mock mode.

### Find warranty data during a failure

A user searches their inventory, opens the appliance, checks warranty status and serial number, then can attach or view the receipt in a future MVP.

### Plan maintenance

A user creates a task such as “Clean dishwasher filter every 90 days”. The dashboard highlights it when due.

## Screens

- Launch and session restoration.
- Dashboard with attention summary and item list.
- Item editor.
- Item details.
- Maintenance task editor and list.
- Settings: language, mock/API mode explanation, logout.

## Risks and mitigation

| Risk | Mitigation |
| --- | --- |
| Users expect automatic receipt extraction | State the manual-first MVP boundary clearly and keep extraction optional. |
| Sensitive inventory data | Default to self-hosting, redact logs, never include production secrets in the repository. |
| Offline edits conflict after sync | Start with cache-first reads and explicit refresh; add conflict resolution only after a stable data model. |
| Too much scope | Maintain non-goals and ship the item-to-maintenance loop before attachments or sharing. |

## Non-goals for v0.1.0

- Insurance claim processing.
- Financial accounting or tax advice.
- Surveillance, hidden tracking, or collection of data from other people.
- Mandatory AI features.
- Marketplace integrations or price scraping.
- Automatic warranty validation against vendors.
