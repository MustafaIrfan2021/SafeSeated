import { useState } from 'react';
import { api } from '../api';
import { Head } from '../ui';
import { money } from '../constants';

export default function Settings() {
  const [s, setS] = useState(api.settings());
  const fare = Math.round(12 * s.ratePerKm), fee = Math.round(fare * s.feePct / 100);
  const field = (k, label) => <label>{label}<input type="number" min="0" value={s[k]} onChange={e => setS({ ...s, [k]: e.target.value })} /></label>;
  async function save() {
    const v = { feePct: +s.feePct, ratePerKm: +s.ratePerKm };
    if (!(v.feePct >= 0 && v.feePct <= 100 && v.ratePerKm > 0)) return alert('Enter a fee between 0 and 100 and a rate above 0.');
    await api.saveSettings(v); api.log('Settings changed', 'fee ' + v.feePct + '%, rate Rs. ' + v.ratePerKm + '/km'); alert('Saved');
  }
  return (<>
    <Head title="Settings" sub="Fare rate and platform commission" />
    <div className="card form">
      {field('ratePerKm', 'Fare rate (Rs. per km, per passenger)')}{field('feePct', 'Platform service fee (%)')}
      <p>Example, 12 km trip: fare <b>{money(fare)}</b>, SafeSeated fee <b>{money(fee)}</b>, driver keeps <b>{money(fare - fee)}</b></p>
      <button onClick={save}>Save settings</button></div></>);
}
