import useCol from '../useCol';
import { Stat, Table, Icon } from '../ui';
import { money, sum } from '../constants';

const review = s => ['Pending Review', 'Under Review'].includes(s);

export default function Dashboard({ go }) {
  const drivers = useCol('drivers'), pass = useCol('passengers'), bookings = useCol('bookings');
  const pay = useCol('payments'), inc = useCol('incidents'), log = useCol('log');
  const generated = sum(pay, p => p.fee), collected = sum(pay.filter(p => p.status === 'Confirmed'), p => p.fee);
  const open = inc.filter(i => i.status === 'Open');
  const todo = [
    ['Driver applications to review', drivers.filter(d => review(d.status)).length, 'drivers', 'driver applications'],
    ['Passenger verifications', pass.filter(p => review(p.status)).length, 'passengers', 'passenger checks'],
    ['Fee payments to confirm', pay.filter(p => p.status === 'Pending Admin Confirmation').length, 'payments', 'payments to confirm'],
    ['Open demo cases', open.length, 'safety', 'demo cases'],
  ];
  const total = todo.reduce((s, t) => s + t[1], 0);
  const today = new Date().toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' });
  return (<>
    <div className="hero">
      <small>{today}</small>
      <h1>Welcome back, Admin</h1>
      <p>{total ? total + ' items need your attention today.' : 'Everything is up to date.'}</p>
      <div className="chips">{todo.filter(t => t[1] > 0).map(([, n, k, s]) => <button key={k} className="chip" onClick={() => go(k)}><b>{n}</b> {s}</button>)}</div>
    </div>
    <h2>Platform</h2>
    <div className="grid">
      <Stat icon="passengers" n={pass.length} l="Passengers" /><Stat icon="drivers" n={drivers.length} l="Drivers" />
      <Stat icon="check" tone="warn" n={drivers.filter(d => review(d.status)).length + pass.filter(p => review(p.status)).length} l="Pending verifications" />
      <Stat icon="safety" tone="good" n={drivers.filter(d => d.status === 'Approved').length} l="Approved drivers" />
      <Stat icon="rides" n={bookings.filter(b => b.status === 'Accepted').length} l="Active bookings" />
      <Stat icon="check" tone="good" n={bookings.filter(b => b.status === 'Completed').length} l="Completed rides" />
      <Stat icon="alert" tone="bad" n={drivers.filter(d => d.status === 'Suspended').length + pass.filter(p => p.account === 'Suspended').length} l="Suspended accounts" />
      <Stat icon="alert" tone={open.length ? 'warn' : ''} n={open.length} l="Open incidents" />
    </div>
    <h2>Finance</h2>
    <div className="grid">
      <Stat icon="payments" n={money(generated)} l="Fees generated" /><Stat icon="check" tone="good" n={money(collected)} l="Fees collected" />
      <Stat icon="alert" tone="warn" n={money(generated - collected)} l="Outstanding" />
      <Stat icon="log" n={pay.filter(p => p.status === 'Pending Admin Confirmation').length} l="Awaiting confirmation" />
    </div>
    <div className="two">
      <div><h2>Pending actions</h2>
        <Table head={['Task', 'Items', '']} rows={todo.map(([t, n, k]) => [t, <b>{n}</b>, <button onClick={() => go(k)}>Open</button>])} /></div>
      <div><h2>Recent activity</h2>
        <Table head={['When', 'Action', 'Target']} rows={log.slice(0, 5).map(l => [l.when, l.action, l.target])} /></div>
    </div></>);
}
