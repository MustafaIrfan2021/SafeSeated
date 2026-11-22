/**
 * SafeSeated API integration plus isolated legacy mock data for Admin sections
 * that do not yet have backend endpoints.
 */
import { DOCS } from './constants';

const docs = (kind, status = 'Approved') => Object.fromEntries(Object.keys(DOCS[kind]).map(k => [k, { file: k + '.jpg', status, note: '' }]));
const rejected = (kind, key, file, note) => { const d = docs(kind, 'Uploaded'); d[key] = { file, status: 'Rejected', note }; return d; };

const data = {
  drivers: [
    { id: 'D1', name: 'Ayesha Khan', phone: '0300-1111111', car: 'Suzuki Cultus 2021 · KHI-1234', area: 'Gulshan-e-Iqbal', status: 'Approved', note: '', date: '02 Sep', docs: docs('drivers') },
    { id: 'D2', name: 'Sana Malik', phone: '0301-2222222', car: 'Honda City 2019 · ABC-567', area: 'North Nazimabad', status: 'Pending Review', note: '', date: '20 Oct', docs: docs('drivers', 'Uploaded') },
    { id: 'D3', name: 'Hira Raza', phone: '0302-3333333', car: 'Toyota Yaris 2020 · BXT-890', area: 'Clifton', status: 'Suspended', note: 'Suspended after complaint C1', date: '11 Aug', docs: docs('drivers') },
    { id: 'D4', name: 'Rabia Ahmed', phone: '0303-4444444', car: 'Toyota Corolla 2018 · KHI-7788', area: 'PECHS', status: 'Under Review', note: '', date: '22 Oct', docs: docs('drivers', 'Uploaded') },
    { id: 'D5', name: 'Komal Siddiqui', phone: '0304-5555555', car: 'Daihatsu Mira 2017 · KHI-3321', area: 'Johar', status: 'Rejected', note: 'CNIC back image is blurry', date: '15 Oct', docs: rejected('drivers', 'cnicBack', 'cnic_back_blurry.jpg', 'Image is blurry') },
    { id: 'D6', name: 'Farah Iqbal', phone: '0305-6666666', car: 'Honda Civic 2020 · KHI-9090', area: 'Gulistan-e-Jauhar', status: 'Resubmission Required', note: 'Driving licence expired. Upload a valid one.', date: '18 Oct', docs: rejected('drivers', 'license', 'licence_old.jpg', 'Licence expired') },
    { id: 'D7', name: 'Mehreen Tariq', phone: '0306-7777777', car: 'Suzuki Wagon R 2022 · KHI-5521', area: 'DHA', status: 'Approved', note: '', date: '05 Sep', docs: docs('drivers') },
    { id: 'D8', name: 'Nida Farooq', phone: '0307-8888888', car: 'Toyota Vitz 2019 · BYH-410', area: 'Bahadurabad', status: 'Approved', note: '', date: '14 Sep', docs: docs('drivers') },
  ],
  passengers: [
    { id: 'P1', name: 'Maryam Ali', phone: '0311-1000001', type: 'University student', inst: 'SMIU', account: 'Active', status: 'Approved', note: '', date: '10 Oct', docs: docs('passengers') },
    { id: 'P2', name: 'Zainab Shah', phone: '0311-1000002', type: 'Bank employee', inst: 'Bank branch, Karachi', account: 'Active', status: 'Pending Review', note: '', date: '24 Oct', docs: docs('passengers', 'Uploaded') },
    { id: 'P3', name: 'Iqra Noor', phone: '0311-1000003', type: 'University student', inst: 'IBA', account: 'Active', status: 'Approved', note: '', date: '12 Oct', docs: docs('passengers') },
    { id: 'P4', name: 'Hina Qureshi', phone: '0311-1000004', type: 'Faculty member', inst: 'SMIU', account: 'Active', status: 'Approved', note: '', date: '13 Oct', docs: docs('passengers') },
    { id: 'P5', name: 'Sidra Javed', phone: '0311-1000005', type: 'University student', inst: 'NED', account: 'Suspended', status: 'Approved', note: '', date: '09 Oct', docs: docs('passengers') },
    { id: 'P6', name: 'Mehwish Rao', phone: '0311-1000006', type: 'Bank employee', inst: 'Bank branch, Karachi', account: 'Active', status: 'Pending Review', note: '', date: '25 Oct', docs: docs('passengers', 'Uploaded') },
  ],
  routes: [
    { id: 'R1', driverId: 'D1', from: 'Gulshan-e-Iqbal', to: 'SMIU Campus', when: '26 Oct · 08:00', seats: 3, fare: 336, status: 'Published' },
    { id: 'R2', driverId: 'D1', from: 'Clifton', to: 'IBA City Campus', when: '26 Oct · 17:30', seats: 2, fare: 420, status: 'Published' },
    { id: 'R3', driverId: 'D1', from: 'North Nazimabad', to: 'Saddar', when: '25 Oct · 09:00', seats: 3, fare: 380, status: 'Cancelled' },
    { id: 'R4', driverId: 'D7', from: 'DHA Phase 5', to: 'NED University', when: '27 Oct · 07:45', seats: 3, fare: 450, status: 'Published' },
    { id: 'R5', driverId: 'D7', from: 'PECHS', to: 'Karachi University', when: '24 Oct · 16:30', seats: 2, fare: 300, status: 'Completed' },
    { id: 'R6', driverId: 'D8', from: 'Bahadurabad', to: 'SZABIST Clifton', when: '28 Oct · 08:15', seats: 3, fare: 380, status: 'Published' },
  ],
  bookings: [
    { id: 'B1', routeId: 'R1', passengerId: 'P3', status: 'Completed' }, { id: 'B2', routeId: 'R2', passengerId: 'P1', status: 'Completed' },
    { id: 'B3', routeId: 'R1', passengerId: 'P1', status: 'Accepted' }, { id: 'B4', routeId: 'R2', passengerId: 'P2', status: 'Pending' },
    { id: 'B5', routeId: 'R1', passengerId: 'P4', status: 'Accepted' }, { id: 'B6', routeId: 'R3', passengerId: 'P6', status: 'Cancelled' },
    { id: 'B7', routeId: 'R4', passengerId: 'P4', status: 'Accepted' }, { id: 'B8', routeId: 'R6', passengerId: 'P3', status: 'Pending' },
  ],
  // Driver service fees owed to SafeSeated. Drivers pay and upload proof; admin confirms.
  payments: [
    { id: 'T1', driverId: 'D1', bookingId: 'B1', fare: 1000, fee: 200, status: 'Confirmed', method: 'JazzCash', ref: 'JC-77120', date: '18 Oct', reason: '' },
    { id: 'T2', driverId: 'D1', bookingId: 'B2', fare: 600, fee: 120, status: 'Pending Admin Confirmation', method: 'Easypaisa', ref: 'EP-88123', date: '23 Oct', reason: '' },
    { id: 'T3', driverId: 'D3', bookingId: '-', fare: 500, fee: 100, status: 'Overdue', method: '', ref: '', date: '05 Oct', reason: '' },
    { id: 'T4', driverId: 'D1', bookingId: 'B3', fare: 420, fee: 84, status: 'Rejected', method: 'Bank transfer', ref: 'BT-0042', date: '21 Oct', reason: 'Reference not found' },
    { id: 'T5', driverId: 'D7', bookingId: 'B5', fare: 300, fee: 60, status: 'Due', method: '', ref: '', date: '24 Oct', reason: '' },
  ],
  incidents: [
    { id: 'C1', type: 'Complaint', text: 'Rude behaviour', driverId: 'D3', reporter: 'P4', status: 'Open', note: '' },
    { id: 'C3', type: 'Complaint', text: 'Wrong route taken', driverId: 'D1', reporter: 'P4', status: 'Open', note: '' },
    { id: 'C4', type: 'Dispute', text: 'Driver asked to change the drop-off point', driverId: 'D8', reporter: 'P3', status: 'Open', note: '' },
    { id: 'C2', type: 'Complaint', text: 'Late arrival', driverId: 'D2', reporter: 'P1', status: 'Resolved', note: 'Warning issued' },
  ],
  log: [
    { when: '19 Oct, 10:05', admin: 'Admin', action: 'Payment confirmed', target: 'T1 / D1', note: '-' },
    { when: '16 Oct, 12:30', admin: 'Admin', action: 'Driver rejected', target: 'D5', note: 'CNIC back image is blurry' },
    { when: '02 Sep, 11:00', admin: 'Admin', action: 'Driver approved', target: 'D1', note: 'All documents verified' },
  ],
  settings: { feePct: 20, ratePerKm: 28 },
};
const subs = new Set();
const wait = ms => new Promise(r => setTimeout(r, ms));
const notify = () => subs.forEach(f => f());
const now = () => new Date().toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5157/api')
  .replace(/\/+$/, '');
const TOKEN_KEY = 'safeseated_admin_token';
const ADMIN_KEY = 'safeseated_admin_user';

function parseError(payload, fallback) {
  if (payload?.title) return payload.title;
  if (payload?.detail) return payload.detail;
  if (payload?.errors) {
    const first = Object.values(payload.errors)[0];
    if (Array.isArray(first) && first[0]) return first[0];
  }
  return fallback;
}

async function request(path, options = {}) {
  const token = localStorage.getItem(TOKEN_KEY);
  let response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      ...options,
      headers: {
        Accept: 'application/json',
        ...(options.body ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options.headers || {}),
      },
    });
  } catch {
    throw new Error('Could not connect to the SafeSeated API.');
  }

  if (response.status === 401) {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent('safeseated-admin-logout'));
    }
  }

  if (response.status === 204) return null;

  const text = await response.text();
  let payload = null;
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = null;
    }
  }
  if (!response.ok) {
    throw new Error(parseError(payload, `Request failed (${response.status}).`));
  }
  return payload;
}

export const api = {
  async login(email, password) {
    const payload = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim(), password }),
    });
    if (!payload?.accessToken) throw new Error('The login response did not contain a token.');
    if (payload.user?.role !== 'Admin') {
      localStorage.removeItem(TOKEN_KEY);
      localStorage.removeItem(ADMIN_KEY);
      throw new Error('This account is not an Admin account.');
    }
    localStorage.setItem(TOKEN_KEY, payload.accessToken);
    localStorage.setItem(ADMIN_KEY, JSON.stringify(payload.user));
    return payload.user;
  },
  restoreSession() {
    if (!localStorage.getItem(TOKEN_KEY)) return null;
    const raw = localStorage.getItem(ADMIN_KEY);
    if (!raw) return null;
    try {
      const user = JSON.parse(raw);
      return user?.role === 'Admin' ? user : null;
    } catch {
      return null;
    }
  },
  logout() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(ADMIN_KEY);
  },
  async adminDocuments(status) {
    const suffix = status && status !== 'All' ? `?status=${encodeURIComponent(status)}` : '';
    return request(`/admin/documents${suffix}`);
  },
  async reviewDocument(id, status) {
    return request(`/admin/documents/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  },
  async emergencyAlerts() {
    return request('/admin/emergency-alerts');
  },
  list: name => data[name],                  // GET /drivers /passengers /routes /bookings /payments /incidents /log
  async update(name, id, patch) {            // PATCH /<name>/:id
    await wait(120);
    Object.assign(data[name].find(x => x.id === id), patch);
    notify();
  },
  // The real backend should write audit-log entries itself (with the logged-in admin's id).
  log(action, target, note = '-') { data.log.unshift({ when: now(), admin: 'Admin', action, target, note }); notify(); },
  settings: () => ({ ...data.settings }),    // GET /settings
  async saveSettings(s) { await wait(120); data.settings = s; notify(); },   // PUT /settings
  subscribe(f) { subs.add(f); return () => subs.delete(f); },
};
