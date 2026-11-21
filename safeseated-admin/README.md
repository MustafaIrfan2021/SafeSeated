# SafeSeated Admin Dashboard (frontend)

React + Vite. The Admin document-review workflow uses the SafeSeated ASP.NET Core API. Other dashboard modules remain demo-only until matching backend endpoints exist.

## Run
    npm install
    npm run dev
Use the existing SafeSeated Admin account.

## Pages
Dashboard, Drivers, Passengers (document review + approve/reject/resubmit/suspend), Rides & bookings,
Payments & fees (confirm / reject / overdue), Complaints & SOS, Settings (fare rate, fee %), Activity log (CSV export).

## For the backend developer
Replace the functions in `src/api.js` with real fetch() calls. Pages do not need to change.

| api function            | Endpoint                                                        |
|-------------------------|-----------------------------------------------------------------|
| login(email, password)  | POST /api/auth/login                                            |
| adminDocuments(status)  | GET /api/admin/documents?status=Pending                         |
| reviewDocument(id,status) | PATCH /api/admin/documents/{id}/status                       |

`list()` and `settings()` are synchronous in the mock. Real calls are async, so load data inside `useCol.js` and `Settings.jsx` with async code.

Security notes: only allow admin roles; re-check on the server that every required document is Approved before a driver or passenger can be approved;
serve identity documents (CNIC, licence) through private, expiring links (put them in `docs[key].url`), never public folders.
