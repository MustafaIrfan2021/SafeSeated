import { useEffect, useState } from 'react';
import { api } from './api';

// Live list from the data layer; re-renders when anything changes
export default function useCol(name) {
  const [rows, setRows] = useState(api.list(name));
  useEffect(() => {
    const sync = () => setRows([...api.list(name)]);
    sync();
    return api.subscribe(sync);
  }, [name]);
  return rows;
}
