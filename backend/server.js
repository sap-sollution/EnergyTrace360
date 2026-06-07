require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

pool.on('error', (err) => console.error('Pool error:', err));

// Health Check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT NOW()');
    res.json({ status: 'healthy', database: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'unhealthy', error: err.message });
  }
});

// ============================================================================
// ASSET SERVICE ENDPOINTS
// ============================================================================

// List Assets
app.get('/api/assets', async (req, res) => {
  try {
    const { status = 'ACTIVE', limit = 50, offset = 0 } = req.query;
    const result = await pool.query(
      'SELECT * FROM asset WHERE status = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
      [status, parseInt(limit), parseInt(offset)]
    );
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM asset WHERE status = $1',
      [status]
    );
    res.json({
      total: parseInt(countResult.rows[0].total),
      limit: parseInt(limit),
      offset: parseInt(offset),
      data: result.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Asset by ID
app.get('/api/assets/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM asset WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Asset not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create Asset
app.post('/api/assets', async (req, res) => {
  try {
    const { name, type, status = 'ACTIVE', location, inspection_frequency_days = 30, created_by = 'system' } = req.body;
    const result = await pool.query(
      'INSERT INTO asset (name, type, status, location, inspection_frequency_days, created_by) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [name, type, status, location, inspection_frequency_days, created_by]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Update Asset
app.put('/api/assets/:id', async (req, res) => {
  try {
    const { status, location, inspection_frequency_days } = req.body;
    const result = await pool.query(
      'UPDATE asset SET status = COALESCE($1, status), location = COALESCE($2, location), inspection_frequency_days = COALESCE($3, inspection_frequency_days), updated_at = NOW() WHERE id = $4 RETURNING *',
      [status, location, inspection_frequency_days, req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Asset not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Record Inspection
app.post('/api/assets/:id/inspections', async (req, res) => {
  try {
    const { inspection_date, result, inspector_id, notes } = req.body;
    const inspectionResult = await pool.query(
      'INSERT INTO inspection (asset_id, inspection_date, result, inspector_id, notes) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [req.params.id, inspection_date, result, inspector_id, notes]
    );
    
    // Update asset last_inspection status
    await pool.query(
      'UPDATE asset SET last_inspection_date = $1, last_inspection_result = $2, next_inspection_due = $1 + (inspection_frequency_days || \' days\')::INTERVAL, updated_at = NOW() WHERE id = $3',
      [inspection_date, result, req.params.id]
    );
    
    res.status(201).json(inspectionResult.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Get Inspection History
app.get('/api/assets/:id/inspections', async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const result = await pool.query(
      'SELECT * FROM inspection WHERE asset_id = $1 ORDER BY inspection_date DESC LIMIT $2 OFFSET $3',
      [req.params.id, parseInt(limit), parseInt(offset)]
    );
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM inspection WHERE asset_id = $1',
      [req.params.id]
    );
    res.json({
      total: parseInt(countResult.rows[0].total),
      limit: parseInt(limit),
      offset: parseInt(offset),
      data: result.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================================
// COMPLIANCE SERVICE ENDPOINTS
// ============================================================================

// Get Compliance Status
app.get('/api/compliance/status', async (req, res) => {
  try {
    const controlsResult = await pool.query('SELECT COUNT(*) as total FROM control');
    const metResult = await pool.query('SELECT COUNT(*) as total FROM control WHERE status = \'MET\'');
    const ncResult = await pool.query(`
      SELECT nc.id, nc.control_id, c.name as control_name, nc.severity, nc.status, nc.identified_date
      FROM non_conformance nc
      JOIN control c ON nc.control_id = c.id
      WHERE nc.status != 'RESOLVED'
      ORDER BY nc.severity DESC, nc.identified_date ASC
    `);
    
    const total = parseInt(controlsResult.rows[0].total);
    const met = parseInt(metResult.rows[0].total);
    const percentage = total > 0 ? ((met / total) * 100).toFixed(1) : 0;
    
    res.json({
      total_controls: total,
      met_controls: met,
      compliance_percentage: parseFloat(percentage),
      non_conformances: ncResult.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Controls for Asset
app.get('/api/compliance/assets/:assetId/controls', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.*, cr.standard, cr.name as rule_name
      FROM control c
      JOIN compliance_rule cr ON c.rule_id = cr.id
      WHERE c.asset_id = $1
      ORDER BY c.created_at DESC
    `, [req.params.assetId]);
    res.json({ total: result.rows.length, data: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create Non-Conformance
app.post('/api/compliance/non-conformances', async (req, res) => {
  try {
    const { control_id, description, severity, root_cause } = req.body;
    const result = await pool.query(
      'INSERT INTO non_conformance (control_id, description, severity, identified_date, status) VALUES ($1, $2, $3, NOW(), \'OPEN\') RETURNING *',
      [control_id, description, severity]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// AUDIT EVIDENCE SERVICE ENDPOINTS
// ============================================================================

// Get Evidence for Asset
app.get('/api/evidence/assets/:assetId', async (req, res) => {
  try {
    const { limit = 10, offset = 0 } = req.query;
    const result = await pool.query(
      'SELECT * FROM audit_evidence WHERE asset_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
      [req.params.assetId, parseInt(limit), parseInt(offset)]
    );
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM audit_evidence WHERE asset_id = $1',
      [req.params.assetId]
    );
    res.json({
      total: parseInt(countResult.rows[0].total),
      limit: parseInt(limit),
      offset: parseInt(offset),
      data: result.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Upload Evidence (Mock - no actual file storage)
app.post('/api/evidence/upload', async (req, res) => {
  try {
    const { asset_id, type, file_name, created_by = 'system' } = req.body;
    const file_url = `/evidence/${asset_id}/${Date.now()}-${file_name}`;
    const result = await pool.query(
      'INSERT INTO audit_evidence (asset_id, type, file_url, file_name, status, created_by) VALUES ($1, $2, $3, $4, \'FINAL\', $5) RETURNING *',
      [asset_id, type, file_url, file_name, created_by]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ============================================================================
// ANALYTICS SERVICE ENDPOINTS
// ============================================================================

// Get Current KPIs
app.get('/api/analytics/kpis', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT * FROM kpi_snapshot
      ORDER BY timestamp DESC
      LIMIT 1
    `);
    if (result.rows.length === 0) {
      return res.json({
        asset_health_index: 0,
        compliance_score: 0,
        audit_readiness: 0,
        maintenance_efficiency: 0,
        supplier_risk_score: 0,
        timestamp: new Date()
      });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get KPI History
app.get('/api/analytics/kpis/history', async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const result = await pool.query(`
      SELECT * FROM kpi_snapshot
      WHERE timestamp > NOW() - INTERVAL '1 day' * $1
      ORDER BY timestamp DESC
    `, [parseInt(days)]);
    res.json({ snapshots: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Error Handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal Server Error', message: err.message });
});

// Start Server
app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});

module.exports = app;
