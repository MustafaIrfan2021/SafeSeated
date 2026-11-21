import { useEffect, useState } from 'react';
import { api } from '../api';
import { Tag, Head, Table, Person } from '../ui';

const DOCUMENT_LABELS = {
  CnicFront: 'CNIC front',
  CnicBack: 'CNIC back',
  StudentCard: 'Student card',
  DrivingLicence: 'Driving licence',
  VehicleRegistration: 'Vehicle registration',
  VehiclePhoto: 'Vehicle photo',
};

const STATUSES = ['All', 'Pending', 'Approved', 'Rejected'];

function formatDate(value) {
  if (!value) return '-';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '-' : date.toLocaleString();
}

export default function Verification({ kind }) {
  const one = kind === 'drivers' ? 'Driver' : 'Passenger';
  const role = one;
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('Pending');
  const [busyId, setBusyId] = useState(null);

  async function load() {
    setLoading(true);
    setError('');
    try {
      setDocuments(await api.adminDocuments(status));
    } catch (requestError) {
      setError(requestError.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [status]);

  async function review(document, nextStatus) {
    setBusyId(document.id);
    setError('');
    try {
      await api.reviewDocument(document.id, nextStatus);
      await load();
    } catch (requestError) {
      setError(requestError.message);
    } finally {
      setBusyId(null);
    }
  }

  const filtered = documents
    .filter((document) => document.user?.role === role)
    .filter((document) => {
      const needle = query.trim().toLowerCase();
      if (!needle) return true;
      return [
        document.user?.fullName,
        document.user?.email,
        document.documentType,
        document.originalFileName,
      ].some((value) => value?.toLowerCase().includes(needle));
    });

  return (
    <>
      <Head
        title={`${one} document verification`}
        sub="Review uploaded identity and vehicle documents"
      />
      <div className="toolbar">
        <input
          placeholder="Search name, email or document"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <select value={status} onChange={(event) => setStatus(event.target.value)}>
          {STATUSES.map((value) => (
            <option key={value}>{value}</option>
          ))}
        </select>
        <button className="alt" onClick={load} disabled={loading}>
          {loading ? 'Loading…' : 'Refresh'}
        </button>
      </div>
      {error && <p className="err" style={{ marginBottom: 12 }}>{error}</p>}

      {loading ? (
        <div className="card" style={{ textAlign: 'center' }}>Loading documents…</div>
      ) : (
        <Table
          head={[
            'Owner',
            'Document',
            'Uploaded',
            'Status',
            'File',
            'Review',
          ]}
          empty="No matching documents."
          rows={filtered.map((document) => [
            <Person
              name={document.user?.fullName || 'Unknown user'}
              sub={document.user?.email || document.userId}
            />,
            DOCUMENT_LABELS[document.documentType] || document.documentType,
            formatDate(document.uploadedAt),
            <Tag s={document.status} />,
            document.fileUrl ? (
              <a
                href={document.fileUrl}
                target="_blank"
                rel="noreferrer"
              >
                {document.originalFileName || 'View document'}
              </a>
            ) : (
              <span className="miss">Unavailable</span>
            ),
            document.status === 'Pending' ? (
              <>
                <button
                  disabled={busyId === document.id}
                  onClick={() => review(document, 'Approved')}
                >
                  Approve
                </button>
                <button
                  className="no"
                  disabled={busyId === document.id}
                  onClick={() => review(document, 'Rejected')}
                >
                  Reject
                </button>
              </>
            ) : (
              '-'
            ),
          ])}
        />
      )}
    </>
  );
}
