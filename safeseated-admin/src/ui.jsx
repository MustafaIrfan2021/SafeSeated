const IC = {
  dashboard: ['M3 3h8v8H3z', 'M13 3h8v5h-8z', 'M13 12h8v9h-8z', 'M3 15h8v6H3z'],
  drivers: ['M4 16v-3l2-5h12l2 5v3', 'M4 16h16v3H4z', 'M7.5 13h.01', 'M16.5 13h.01'],
  passengers: ['M16 20v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 18.5V20', 'M10 12a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z', 'M20 20v-1.5a3.5 3.5 0 0 0-2.5-3.3', 'M15.5 5.2a3.5 3.5 0 0 1 0 6.6'],
  rides: ['M6 19a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', 'M18 9a2 2 0 1 0 0-4 2 2 0 0 0 0 4z', 'M8 17h8a3 3 0 0 0 0-6H8a3 3 0 0 1 0-6h8'],
  payments: ['M4 7h15a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h12', 'M16 13h.01'],
  safety: ['M12 3l8 3v6c0 4.5-3.2 8-8 9-4.8-1-8-4.5-8-9V6z', 'M9 12l2 2 4-4'],
  settings: ['M4 7h10', 'M18 7h2', 'M4 17h2', 'M10 17h10', 'M14 5v4', 'M6 15v4'],
  log: ['M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z', 'M12 7v5l3 2'],
  logout: ['M9 21H5V3h4', 'M16 17l5-5-5-5', 'M21 12H9'],
  alert: ['M12 3l10 18H2z', 'M12 10v4', 'M12 17h.01'],
  check: ['M5 12l5 5 9-10'],
  mail: ['M4 6h16v12H4z', 'M4 7l8 6 8-6'],
  lock: ['M6 11h12v9H6z', 'M8 11V8a4 4 0 0 1 8 0v3'],
  eye: ['M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z', 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z'],
  eyeoff: ['M3 3l18 18', 'M10.6 6.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3 3.9', 'M6.6 6.6A17 17 0 0 0 2 12s3.5 7 10 7c1.6 0 3-.3 4.3-.9'],
};
export const Icon = ({ name, size = 18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    {(IC[name] || []).map((d, i) => <path key={i} d={d} />)}</svg>);

const tone = s => /Approved|Confirmed|Active|Completed|Resolved|Closed|Accepted|Published/.test(s) ? 'g'
  : /Reject|Suspended|Overdue|Cancelled|SOS|Dispute/.test(s) ? 'r' : 'a';
export const Tag = ({ s }) => <span className={'tag ' + tone(s)}>{s}</span>;
export const Stat = ({ n, l, icon, tone: t = '' }) => (
  <div className={'card stat ' + t}>{icon && <i className="si"><Icon name={icon} /></i>}<div><b>{n}</b><span>{l}</span></div></div>);
export const Person = ({ name, sub }) => (
  <div className="person"><span className="av">{name.split(' ').slice(0, 2).map(w => w[0]).join('')}</span>
    <div><b>{name}</b>{sub && <small>{sub}</small>}</div></div>);
export const Head = ({ title, sub, children }) => (
  <div className="head"><div><h1>{title}</h1><p className="sub">{sub}</p></div><div>{children}</div></div>);
export const Table = ({ head, rows, empty = 'Nothing here.' }) => (
  <div className="card scroll"><table>
    <thead><tr>{head.map(h => <th key={h}>{h}</th>)}</tr></thead>
    <tbody>{rows.map((r, i) => <tr key={i}>{r.map((c, j) => <td key={j}>{c}</td>)}</tr>)}</tbody>
  </table>{!rows.length && <p className="emp">{empty}</p>}</div>);
