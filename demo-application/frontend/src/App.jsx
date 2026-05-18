import { useEffect, useState } from 'react';

export default function App() {
  const [info, setInfo] = useState(null);
  const [items, setItems] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    Promise.all([
      fetch('/api/info').then((r) => r.json()),
      fetch('/api/items').then((r) => r.json()),
    ])
      .then(([infoRes, itemsRes]) => {
        setInfo(infoRes);
        setItems(itemsRes.items || []);
      })
      .catch((err) => setError(err.message));
  }, []);

  return (
    <div className="container">
      <header>
        <h1>DevOps Take-Home Demo</h1>
        <p className="subtitle">
          Node.js + React on Huawei Cloud (CCE) — full CI/CD &amp; Observability
        </p>
      </header>

      {error && <div className="error">Failed to reach backend: {error}</div>}

      <section className="card">
        <h2>Backend Info</h2>
        {info ? (
          <table>
            <tbody>
              <tr>
                <td>Service</td>
                <td>{info.service}</td>
              </tr>
              <tr>
                <td>Version</td>
                <td>{info.version}</td>
              </tr>
              <tr>
                <td>Color (Blue-Green)</td>
                <td>
                  <span className={`tag tag-${info.color}`}>{info.color}</span>
                </td>
              </tr>
              <tr>
                <td>Hostname (Pod)</td>
                <td>
                  <code>{info.hostname}</code>
                </td>
              </tr>
              <tr>
                <td>Uptime</td>
                <td>{info.uptime_seconds}s</td>
              </tr>
            </tbody>
          </table>
        ) : (
          <p>Loading...</p>
        )}
      </section>

      <section className="card">
        <h2>Items from API</h2>
        <ul>
          {items.map((it) => (
            <li key={it.id}>{it.name}</li>
          ))}
        </ul>
      </section>

      <footer>
        <small>
          Built for the 7-Day DevOps Challenge — Terraform · Docker · K8s · Prometheus · Grafana
        </small>
      </footer>
    </div>
  );
}
