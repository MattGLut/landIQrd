# landIQrd feature set

What the app does today, feature by feature. Each page is a short click path and a screenshot. The proposal flow also has a longer picture tour in [the marketplace walkthrough](../walkthrough/README.md).

Shots below are from the demo database. Every seeded account uses `password123`.

| Role | Email |
|---|---|
| Landlord | `landlord@propman.test` |
| Contractor | `contractor@propman.test` |
| Tenant | `tenant@propman.test` |
| Admin | `admin@propman.test` |

Four roles share one app: the building, the lease, the repair, and the bid. HOA dues and violations are a different product, neIQhbor, and they are not in this repo.

## Ready to show

These flows work from sign-in through the last click.

| Feature | Who |
|---|---|
| [Sign in and account](sign-in-and-account.md) | Everyone |
| [Dashboards](dashboards.md) | Landlord, contractor, tenant |
| [Properties and units](properties-and-units.md) | Landlord |
| [Leases](leases.md) | Landlord, tenant |
| [Lease invitations](lease-invitations.md) | Landlord, tenant |
| [Work orders](work-orders.md) | Landlord, tenant, contractor |
| [Assigning a contractor](assigning-contractors.md) | Landlord, contractor |
| [Quick jobs](quick-jobs.md) | Landlord, contractor |
| [Messages](messages.md) | Landlord, contractor, tenant |
| [Email notifications](notifications.md) | Landlord, contractor, tenant |
| [Contractor directory and portfolio](contractor-directory.md) | Landlord, contractor |
| [Request for proposals](proposals.md) | Landlord, contractor |
| [Walkthrough times](walkthroughs.md) | Landlord, contractor |
| [Proposals and award](award.md) | Landlord, contractor |

## In the app, with a limit

The screen is there. The note on each page is the part a partner will notice.

| Feature | Limit |
|---|---|
| [Service-area matching](matching.md) | City and state text. The mile radius is stored and does not change who is ranked. |
| [Photo thumbnails](photos.md) | Job photos display. Avatars, portfolio shots, and work-order thumbnails need an image library this machine does not have. |
| [Schedule](schedule.md) | A list of upcoming visits, not a calendar. Walkthrough bookings are on a different page. |
| [Admin console](admin.md) | Users can be edited. Properties, work orders, and conversations are view-only. Jobs are not in the console. |

## Not in the product

No screen and no table. Listed in [Not built yet](not-yet.md) so a walkthrough does not imply them.

Payments, a pricing page, listings and applications, screening and e-sign, inspections, accounting, reviews, staff seats under a landlord, and stricter sign-in (email confirmation, lockout, a second factor).
