import { useState } from 'react';
import { api } from '../api';
import useCol from '../useCol';
import { Tag, Head, Table } from '../ui';
import { money } from '../constants';

export default function Rides() {
  const routes = useCol('routes'), bookings = useCol('bookings'), drivers = useCol('drivers'), pass = useCol('passengers');
  const [tab, setTab] = useState('rides'), [q, setQ] = useState('');
  const name = (a, id) => a.find(x => x.id === id)?.name || id;
  const route = id => routes.find(r => r.id === id);
  const match = s => s.toLowerCase().includes(q.toLowerCase());

  async function cancel(r) {
    const why = prompt('Reason for cancelling this ride', 'Cancelled by admin');
    if (!why) return;
    await api.update('routes', r.id, { status: 'Cancelled' });
    for (const b of bookings.filter(b => b.routeId === r.id && ['Pending', 'Accepted'].includes(b.status))) await api.update('bookings', b.id, { status: 'Cancelled' });
    api.log('Ride cancelled', r.id, why);
  }
  return (<>
    <Head title="Rides & bookings" sub="Monitor published rides and passenger booking requests" />
    <div className="toolbar">
      <div className="seg"><button className={tab === 'rides' ? 'on' : ''} onClick={() => setTab('rides')}>Rides</button>
        <button className={tab === 'bookings' ? 'on' : ''} onClick={() => setTab('bookings')}>Bookings</button></div>
      <input placeholder="Search" value={q} onChange={e => setQ(e.target.value)} />
    </div>
    {tab === 'rides'
      ? <Table head={['Ride', 'Driver', 'Route', 'When', 'Seats', 'Fare / seat', 'Status', '']}
          rows={routes.filter(r => match(r.id + name(drivers, r.driverId) + r.from + r.to)).map(r => [r.id, name(drivers, r.driverId), r.from + ' → ' + r.to, r.when, r.seats, money(r.fare), <Tag s={r.status} />,
            r.status === 'Published' && <button className="no" onClick={() => cancel(r)}>Cancel</button>])} />
      : <Table head={['Booking', 'Passenger', 'Ride', 'Route', 'Status']}
          rows={bookings.filter(b => match(b.id + name(pass, b.passengerId))).map(b => [b.id, name(pass, b.passengerId), b.routeId, route(b.routeId) ? route(b.routeId).from + ' → ' + route(b.routeId).to : '-', <Tag s={b.status} />])} />}
  </>);
}
