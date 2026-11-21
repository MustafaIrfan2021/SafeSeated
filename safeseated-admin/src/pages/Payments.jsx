import { useState } from 'react';
import { api } from '../api';
import useCol from '../useCol';
import { Tag, Stat, Head, Table } from '../ui';
import { money, sum } from '../constants';

const FILTERS = { All: () => true, Pending: p => p.status === 'Pending Admin Confirmation', Confirmed: p => p.status === 'Confirmed', Rejected: p => p.status === 'Rejected', Overdue: p => p.status === 'Overdue' };

export default function Payments() {
  const pay = useCol('payments'), drivers = useCol('drivers'), [f, setF] = useState('All');
  const generated = sum(pay, p => p.fee), collected = sum(pay.filter(p => p.status === 'Confirmed'), p => p.fee);
  const who = id => drivers.find(d => d.id === id)?.name || id;

  async function act(p, a) {
    if (a === 'ok') {
      if (!confirm('Confirm ' + money(p.fee) + ' received from ' + who(p.driverId) + '?')) return;
      await api.update('payments', p.id, { status: 'Confirmed', reason: '' }); api.log('Payment confirmed', p.id + ' / ' + p.driverId);
    } else if (a === 'no') {
      const r = prompt('Rejection reason', 'Reference not found'); if (!r) return;
      await api.update('payments', p.id, { status: 'Rejected', reason: r }); api.log('Payment rejected', p.id, r);
    } else { await api.update('payments', p.id, { status: 'Overdue' }); api.log('Marked overdue', p.id); }
  }
  return (<>
    <Head title="Payments & service fees" sub="Drivers pay the platform fee and upload proof. Admin checks and confirms." />
    <div className="grid">
      <Stat icon="payments" n={money(generated)} l="Fees generated" /><Stat icon="check" tone="good" n={money(collected)} l="Fees collected" />
      <Stat icon="alert" tone="warn" n={money(generated - collected)} l="Outstanding" /><Stat icon="log" n={pay.filter(FILTERS.Pending).length} l="Awaiting confirmation" />
    </div>
    <div className="seg">{Object.keys(FILTERS).map(k => <button key={k} className={f === k ? 'on' : ''} onClick={() => setF(k)}>{k}</button>)}</div>
    <Table head={['Txn', 'Driver', 'Ride fare', 'Fee', 'Date', 'Method / reference', 'Status', '']}
      rows={pay.filter(FILTERS[f]).map(p => [p.id, who(p.driverId) + ' (' + p.driverId + ')', money(p.fare), money(p.fee), p.date,
        p.method ? p.method + ' · ' + p.ref : '-', <><Tag s={p.status} />{p.reason && <small><br />{p.reason}</small>}</>,
        p.status === 'Pending Admin Confirmation' ? <><button onClick={() => act(p, 'ok')}>Confirm received</button><button className="no" onClick={() => act(p, 'no')}>Reject</button></>
          : p.status === 'Due' ? <button className="alt" onClick={() => act(p, 'od')}>Mark overdue</button> : null])} />
  </>);
}
