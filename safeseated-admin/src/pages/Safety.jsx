import { useEffect, useState } from 'react';
import { api } from '../api';
import { Head, Table, Tag } from '../ui';

function formatTime(value) {
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? 'Unknown' : date.toLocaleString();
}

function emergencyContact(alert) {
  const contact = alert.user?.emergencyContactPhone;
  return contact
    ? <a href={`tel:${contact}`}>{alert.user.emergencyContactName || 'Emergency contact'} · {contact}</a>
    : 'Not configured';
}

function alertLocation(alert) {
  if (!Number.isFinite(alert.latitude) || !Number.isFinite(alert.longitude)) {
    return 'Unavailable';
  }
  const url = `https://www.google.com/maps/search/?api=1&query=${alert.latitude},${alert.longitude}`;
  return <a href={url} target="_blank" rel="noreferrer">View map</a>;
}

export default function Safety() {
  const [alerts, setAlerts] = useState([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [reload, setReload] = useState(0);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError('');
    api.emergencyAlerts()
      .then(items => {
        if (!Array.isArray(items)) throw new Error('The API returned an invalid SOS alert list.');
        if (active) setAlerts(items);
      })
      .catch(cause => {
        if (active) setError(cause.message || 'Could not load SOS alerts.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [reload]);

  const rows = alerts.map(alert => [
    formatTime(alert.createdAt),
    <>{alert.user?.name || 'Unknown user'}<small><br />{alert.role || alert.user?.role || 'Unknown role'} · {alert.user?.phone || 'No phone'}</small></>,
    emergencyContact(alert),
    alert.ride
      ? <>{alert.ride.pickup} → {alert.ride.destination}<small><br />{alert.ride.status} · {formatTime(alert.ride.departureTime)}</small></>
      : 'Not linked to a ride',
    alertLocation(alert),
    <Tag s={alert.status || 'Open'} />,
  ]);

  return (<>
    <Head title="Emergency SOS alerts" sub="Recent alerts sent by authenticated Passenger and Driver accounts." />
    <div className="note">SOS alerts are stored for Admin review. The system does not automatically contact emergency services or dispatch a response team.</div>
    {loading && <p className="emp">Loading SOS alerts…</p>}
    {error && <div className="note" role="alert">{error}<button className="alt" onClick={() => setReload(value => value + 1)}>Retry</button></div>}
    {!loading && !error && alerts.length === 0 && <p className="emp">No SOS alerts have been received.</p>}
    {!loading && !error && alerts.length > 0 && (
      <Table head={['Received', 'User', 'Emergency contact', 'Ride', 'Location', 'Status']} rows={rows} />
    )}
    <button className="alt" onClick={() => setReload(value => value + 1)} disabled={loading}>Refresh alerts</button>
  </>);
}
