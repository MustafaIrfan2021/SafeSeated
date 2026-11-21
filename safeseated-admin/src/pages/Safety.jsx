import { api } from '../api';
import useCol from '../useCol';
import { Tag, Head, Table } from '../ui';

export default function Safety() {
  const inc = useCol('incidents'), drivers = useCol('drivers');
  const who = id => drivers.find(d => d.id === id)?.name || '-';
  const sorted = [...inc].sort((a, b) => (b.status === 'Open') - (a.status === 'Open') || (b.type === 'SOS') - (a.type === 'SOS'));

  async function resolve(i) {
    const note = prompt('Resolution note', 'Warning issued to driver'); if (!note) return;
    await api.update('incidents', i.id, { status: 'Resolved', note }); api.log('Incident resolved', i.id, note);
  }
  async function suspend(i) {
    if (!confirm('Suspend ' + who(i.driverId) + '?')) return;
    await api.update('drivers', i.driverId, { status: 'Suspended', note: 'Suspended after ' + i.id });
    api.log('Driver suspended', i.driverId, 'Incident ' + i.id);
  }
  return (<>
    <Head title="Complaints, disputes & SOS" sub="Open cases appear first. SOS alerts are always at the top." />
    <div className="note">Production note: a real SOS flow needs a named response owner, an escalation policy, location-sharing consent and end-to-end testing. This screen only lists and tracks the cases.</div>
    <Table head={['Case', 'Type', 'Details', 'Driver', 'Reported by', 'Status', '']}
      rows={sorted.map(i => [i.id, <Tag s={i.type === 'SOS' ? 'SOS' : i.type} />, <>{i.text}{i.note && <small><br />{i.note}</small>}</>, who(i.driverId), i.reporter, <Tag s={i.status} />,
        i.status === 'Open' && <><button onClick={() => resolve(i)}>Resolve</button><button className="no" onClick={() => suspend(i)}>Suspend driver</button></>])} />
  </>);
}
