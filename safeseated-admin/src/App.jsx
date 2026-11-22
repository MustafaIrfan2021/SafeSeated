import { useEffect, useState } from 'react';
import { api } from './api';
import { Icon } from './ui';
import Dashboard from './pages/Dashboard.jsx';
import Verification from './pages/Verification.jsx';
import Rides from './pages/Rides.jsx';
import Payments from './pages/Payments.jsx';
import Safety from './pages/Safety.jsx';
import Settings from './pages/Settings.jsx';
import Log from './pages/Log.jsx';

const TABS = [['dashboard', 'Dashboard', 'dashboard'], ['drivers', 'Drivers', 'drivers'], ['passengers', 'Passengers', 'passengers'], ['rides', 'Rides & bookings', 'rides'],
  ['payments', 'Payments & fees', 'payments'], ['safety', 'Emergency SOS', 'safety'], ['settings', 'Settings', 'settings'], ['log', 'Activity log', 'log']];

export default function App() {
  const [user, setUser] = useState(() => api.restoreSession()), [tab, setTab] = useState('dashboard'), [err, setErr] = useState(''), [show, setShow] = useState(false), [busy, setBusy] = useState(false);
  const demoTabs = new Set(['dashboard', 'rides', 'payments', 'settings', 'log']);

  useEffect(() => {
    const handleLogout = () => setUser(null);
    window.addEventListener('safeseated-admin-logout', handleLogout);
    return () => window.removeEventListener('safeseated-admin-logout', handleLogout);
  }, []);

  async function login(e) {
    e.preventDefault(); setErr(''); setBusy(true);
    const f = new FormData(e.target);
    try { setUser(await api.login(f.get('email'), f.get('password'))); } catch (x) { setErr(x.message); }
    setBusy(false);
  }
  if (!user) return (
    <div className="lg">
      <section className="lg-art">
        <div className="lg-brand"><span className="lg-mark"><Icon name="safety" size={22} /></span>SafeSeated</div>
        <div>
          <h2>Safer commutes, managed with care.</h2>
          <p>The operations workspace for SafeSeated, the women-only carpooling service. Verify members, support drivers and keep every ride accountable.</p>
          <ul className="lg-feat">
            <li><i><Icon name="check" size={18} /></i>Verify drivers and passengers with document review</li>
            <li><i><Icon name="payments" size={18} /></i>Track rides, service fees and payments</li>
            <li><i><Icon name="alert" size={18} /></i>Respond quickly to complaints and SOS alerts</li>
          </ul>
        </div>
        <div>
          <svg className="lg-route" viewBox="0 0 440 120" fill="none" aria-hidden="true">
            <path d="M20 96C110 10 200 130 290 62S400 22 420 30" stroke="#fff" strokeOpacity=".55" strokeWidth="2" strokeDasharray="5 7" strokeLinecap="round" />
            <circle cx="20" cy="96" r="7" fill="#fff" /><circle cx="215" cy="78" r="5" fill="#fff" fillOpacity=".7" />
            <circle cx="420" cy="30" r="9" fill="#fff" /><circle cx="420" cy="30" r="3.5" fill="#5947c3" />
          </svg>
          <div className="lg-foot">© SafeSeated · Karachi</div>
        </div>
      </section>
      <section className="lg-form">
        <form className="lg-card" onSubmit={login}>
          <div className="lg-badge"><Icon name="lock" size={22} /></div>
          <div><h1>Welcome back</h1><p className="sub">Sign in to the admin workspace</p></div>
          <label>Email
            <div className="field"><Icon name="mail" size={17} /><input name="email" type="email" defaultValue="admin@safeseated.pk" autoComplete="username" required /></div></label>
          <label>Password
            <div className="field"><Icon name="lock" size={17} />
              <input name="password" type={show ? 'text' : 'password'} autoComplete="current-password" required />
              <button type="button" className="eye" onClick={() => setShow(!show)} aria-label={show ? 'Hide password' : 'Show password'}><Icon name={show ? 'eyeoff' : 'eye'} size={18} /></button></div></label>
          {err && <p className="err">{err}</p>}
          <button className="big" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
          <div className="lg-note"><Icon name="shield" size={16} />Authorised staff only. Document review actions are secured by the Admin role.</div>
        </form>
      </section>
    </div>);

  return (
    <div className="shell">
      <aside>
        <div className="brand"><div><b>SafeSeated</b><small>Admin workspace</small></div></div>
        <nav>{TABS.map(([k, l, ic]) => <button key={k} className={tab === k ? 'on' : ''} onClick={() => setTab(k)}><Icon name={ic} />{l}</button>)}</nav>
        <div className="me"><span className="av">A</span><div><b>Admin</b><small>Operations</small></div>
          <button className="out" onClick={() => { api.logout(); setUser(null); }} aria-label="Sign out" title="Sign out"><Icon name="logout" /></button></div>
      </aside>
      <main key={tab}>
        {demoTabs.has(tab) && <div className="demo-banner"><b>Demo only</b> — this section is not connected to a backend endpoint.</div>}
        {tab === 'dashboard' && <Dashboard go={setTab} />}
        {tab === 'drivers' && <Verification kind="drivers" />}
        {tab === 'passengers' && <Verification kind="passengers" />}
        {tab === 'rides' && <Rides />}
        {tab === 'payments' && <Payments />}
        {tab === 'safety' && <Safety />}
        {tab === 'settings' && <Settings />}
        {tab === 'log' && <Log />}
      </main>
    </div>);
}
