import React, { useEffect, useState } from 'react';
import axios from 'axios';
import './Dashboard.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001/api';

function Dashboard() {
  const [kpis, setKpis] = useState(null);
  const [assets, setAssets] = useState([]);
  const [compliance, setCompliance] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch KPIs
        const kpiRes = await axios.get(`${API_URL}/analytics/kpis`);
        setKpis(kpiRes.data);

        // Fetch Assets
        const assetsRes = await axios.get(`${API_URL}/assets?limit=10`);
        setAssets(assetsRes.data.data);

        // Fetch Compliance Status
        const complianceRes = await axios.get(`${API_URL}/compliance/status`);
        setCompliance(complianceRes.data);

        setLoading(false);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) return <div className="container"><p>Loading...</p></div>;
  if (error) return <div className="container error"><p>Error: {error}</p></div>;

  return (
    <div className="container">
      <header className="header">
        <h1>EnergyTrace360</h1>
        <p>Asset Integrity & Compliance Reference Architecture</p>
      </header>

      {/* KPI Cards */}
      <section className="kpi-section">
        <h2>Key Performance Indicators</h2>
        <div className="kpi-grid">
          <KPICard
            title="Asset Health Index"
            value={kpis?.asset_health_index || 0}
            unit="%"
            color="#2196F3"
          />
          <KPICard
            title="Compliance Score"
            value={kpis?.compliance_score || 0}
            unit="%"
            color="#4CAF50"
          />
          <KPICard
            title="Audit Readiness"
            value={kpis?.audit_readiness || 0}
            unit="%"
            color="#FF9800"
          />
          <KPICard
            title="Maintenance Efficiency"
            value={kpis?.maintenance_efficiency || 0}
            unit="%"
            color="#9C27B0"
          />
          <KPICard
            title="Supplier Risk Score"
            value={kpis?.supplier_risk_score || 0}
            unit="%"
            color="#F44336"
          />
        </div>
      </section>

      {/* Compliance Status */}
      {compliance && (
        <section className="compliance-section">
          <h2>Compliance Status</h2>
          <div className="compliance-card">
            <p>Total Controls: <strong>{compliance.total_controls}</strong></p>
            <p>Met Controls: <strong>{compliance.met_controls}</strong></p>
            <p>Compliance Percentage: <strong>{compliance.compliance_percentage}%</strong></p>
            {compliance.non_conformances && compliance.non_conformances.length > 0 && (
              <div className="non-conformances">
                <h3>Open Non-Conformances:</h3>
                <ul>
                  {compliance.non_conformances.map((nc) => (
                    <li key={nc.id}>
                      <strong>{nc.control_name}</strong> - Severity: {nc.severity}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </section>
      )}

      {/* Assets Overview */}
      <section className="assets-section">
        <h2>Active Assets</h2>
        <table className="assets-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Status</th>
              <th>Location</th>
              <th>Last Inspection</th>
            </tr>
          </thead>
          <tbody>
            {assets.map((asset) => (
              <tr key={asset.id}>
                <td>{asset.name}</td>
                <td>{asset.type}</td>
                <td><span className={`status ${asset.status.toLowerCase()}`}>{asset.status}</span></td>
                <td>{asset.location}</td>
                <td>{asset.last_inspection_result || 'N/A'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}

function KPICard({ title, value, unit, color }) {
  return (
    <div className="kpi-card" style={{ borderLeft: `4px solid ${color}` }}>
      <h3>{title}</h3>
      <div className="kpi-value" style={{ color }}>
        {value.toFixed(1)}<span className="unit">{unit}</span>
      </div>
    </div>
  );
}

export default Dashboard;
