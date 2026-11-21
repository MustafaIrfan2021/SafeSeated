import useCol from '../useCol';
import { Head, Table } from '../ui';

export default function Log() {
  const log = useCol('log');
  function exportCsv() {
    const csv = ['When,Admin,Action,Target,Note', ...log.map(l => [l.when, l.admin, l.action, l.target, l.note].map(v => '"' + String(v).replace(/"/g, '""') + '"').join(','))].join('\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' })); a.download = 'safeseated-audit-log.csv'; a.click();
  }
  return (<>
    <Head title="Activity log" sub="Every admin action is recorded for accountability"><button onClick={exportCsv}>Export CSV</button></Head>
    <Table head={['When', 'Admin', 'Action', 'Target', 'Note']} rows={log.map(l => [l.when, l.admin, l.action, l.target, l.note])} />
  </>);
}
