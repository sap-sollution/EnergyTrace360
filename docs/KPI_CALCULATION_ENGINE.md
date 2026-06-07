# KPI Calculation Engine

## Overview

The KPI engine provides shared calculation logic across all services. It's implemented as utility functions that can be called by any service needing real-time KPI metrics.

---

## 1. Asset Health Index

**Formula:**
```
Asset Health Index = (Total Assets Inspected With PASS Result / Total Assets) × 100
```

**Calculation:**
```sql
SELECT 
    COUNT(CASE WHEN last_inspection_result = 'PASS' THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(*), 0) * 100 AS asset_health_index
FROM asset
WHERE status = 'ACTIVE';
```

**Service Location:** `backend/services/asset-service/kpi.js`

**Code Example:**
```javascript
async function calculateAssetHealth(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_assets,
      COUNT(CASE WHEN last_inspection_result = 'PASS' THEN 1 END) as passed,
      COUNT(CASE WHEN last_inspection_result = 'FAIL' THEN 1 END) as failed
    FROM asset
    WHERE status = 'ACTIVE'
  `);
  
  const { total_assets, passed, failed } = result.rows[0];
  
  if (total_assets === 0) return 0;
  
  return {
    value: (passed / total_assets * 100).toFixed(2),
    total_assets,
    passed,
    failed,
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 30 seconds (real-time polling)

**Endpoint:** `GET /api/kpi/asset-health`

---

## 2. Compliance Score

**Formula:**
```
Compliance Score = (Controls with Status MET / Total Controls) × 100
```

**Calculation:**
```sql
SELECT 
    COUNT(CASE WHEN status = 'MET' THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(*), 0) * 100 AS compliance_score
FROM control;
```

**Service Location:** `backend/services/compliance-service/kpi.js`

**Code Example:**
```javascript
async function calculateComplianceScore(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_controls,
      COUNT(CASE WHEN status = 'MET' THEN 1 END) as met_controls,
      COUNT(CASE WHEN status = 'PENDING' THEN 1 END) as pending_controls,
      COUNT(CASE WHEN status = 'NOT_MET' THEN 1 END) as not_met_controls
    FROM control
  `);
  
  const { total_controls, met_controls, pending_controls, not_met_controls } = result.rows[0];
  
  if (total_controls === 0) return 0;
  
  return {
    value: (met_controls / total_controls * 100).toFixed(2),
    met_controls,
    pending_controls,
    not_met_controls,
    total_controls,
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 1 hour (batch job)

**Endpoint:** `GET /api/kpi/compliance-score`

---

## 3. Audit Readiness

**Formula:**
```
Audit Readiness = (Controls with Linked Evidence / Controls Requiring Evidence) × 100
```

**Calculation:**
```sql
SELECT 
    COUNT(CASE WHEN el.id IS NOT NULL THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(*), 0) * 100 AS audit_readiness
FROM control c
LEFT JOIN evidence_link el ON c.id = el.control_id
WHERE c.evidence_required = TRUE;
```

**Service Location:** `backend/services/evidence-service/kpi.js`

**Code Example:**
```javascript
async function calculateAuditReadiness(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(DISTINCT c.id) as total_controls_requiring_evidence,
      COUNT(DISTINCT c.id) FILTER (WHERE el.id IS NOT NULL) as controls_with_evidence
    FROM control c
    LEFT JOIN evidence_link el ON c.id = el.control_id
    WHERE c.evidence_required = TRUE
  `);
  
  const { total_controls_requiring_evidence, controls_with_evidence } = result.rows[0];
  
  if (total_controls_requiring_evidence === 0) return 100;
  
  return {
    value: (controls_with_evidence / total_controls_requiring_evidence * 100).toFixed(2),
    total_required: total_controls_requiring_evidence,
    with_evidence: controls_with_evidence,
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 1 hour

**Endpoint:** `GET /api/kpi/audit-readiness`

---

## 4. Maintenance Efficiency

**Formula:**
```
Maintenance Efficiency = (Assets with Planned Maintenance / Total Assets) × 100

Planned Maintenance = Inspections recorded on or before next_inspection_due date
```

**Calculation:**
```sql
SELECT 
    COUNT(CASE WHEN last_inspection_date <= next_inspection_due THEN 1 END)::DECIMAL / 
    NULLIF(COUNT(*), 0) * 100 AS maintenance_efficiency
FROM asset
WHERE status IN ('ACTIVE', 'MAINTENANCE');
```

**Service Location:** `backend/services/asset-service/kpi.js`

**Code Example:**
```javascript
async function calculateMaintenanceEfficiency(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_assets,
      COUNT(CASE WHEN last_inspection_date <= next_inspection_due THEN 1 END) as planned_maintenance
    FROM asset
    WHERE status IN ('ACTIVE', 'MAINTENANCE')
  `);
  
  const { total_assets, planned_maintenance } = result.rows[0];
  
  if (total_assets === 0) return 0;
  
  return {
    value: (planned_maintenance / total_assets * 100).toFixed(2),
    total_assets,
    planned_maintenance,
    unplanned: total_assets - planned_maintenance,
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 24 hours (daily)

**Endpoint:** `GET /api/kpi/maintenance-efficiency`

---

## 5. Supplier Risk Score

**Formula:**
```
Supplier Risk Score = (Average Supplier Rating × 10)

Where Supplier Rating is 0-10 scale from SAP MM Adapter
```

**Calculation:**
```sql
SELECT 
    AVG(rating) * 10 AS supplier_risk_score
FROM supplier
WHERE rating > 0;  -- Exclude unrated
```

**Service Location:** `backend/services/sap-mock-adapter/kpi.js`

**Code Example:**
```javascript
async function calculateSupplierRiskScore(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_suppliers,
      COUNT(CASE WHEN rating >= 8 THEN 1 END) as green_rated,
      COUNT(CASE WHEN rating >= 6 AND rating < 8 THEN 1 END) as yellow_rated,
      COUNT(CASE WHEN rating < 6 THEN 1 END) as red_rated,
      AVG(rating) as avg_rating
    FROM supplier
    WHERE rating > 0
  `);
  
  const { total_suppliers, green_rated, yellow_rated, red_rated, avg_rating } = result.rows[0];
  
  if (!avg_rating) return 0;
  
  return {
    value: (avg_rating * 10).toFixed(2),
    avg_rating: avg_rating.toFixed(2),
    total_suppliers,
    green_rated,
    yellow_rated,
    red_rated,
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 24 hours

**Endpoint:** `GET /api/kpi/supplier-risk`

---

## 6. Purchase Orders Open

**Formula:**
```
PO Open Count = COUNT(Purchase Orders WHERE status = 'OPEN')
```

**Calculation:**
```sql
SELECT COUNT(*) as po_open_count
FROM purchase_order
WHERE status = 'OPEN';
```

**Service Location:** `backend/services/sap-mock-adapter/kpi.js`

**Code Example:**
```javascript
async function calculatePOMetrics(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(*) as total_po,
      COUNT(CASE WHEN status = 'OPEN' THEN 1 END) as open_po,
      COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_po,
      COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) as cancelled_po
    FROM purchase_order
  `);
  
  const { total_po, open_po, completed_po, cancelled_po } = result.rows[0];
  
  return {
    open_count: open_po,
    total_count: total_po,
    completed_count: completed_po,
    cancelled_count: cancelled_po,
    completion_rate: ((completed_po / total_po) * 100).toFixed(2),
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 1 hour

**Endpoint:** `GET /api/kpi/po-metrics`

---

## 7. Invoice Completion Rate

**Formula:**
```
Invoice Completion Rate = (Total Invoiced Amount / Total Order Amount) × 100
```

**Calculation:**
```sql
SELECT 
    COALESCE(SUM(i.amount), 0)::DECIMAL / 
    NULLIF(SUM(so.total_amount), 0) * 100 AS invoice_completion_rate
FROM sales_order so
LEFT JOIN invoice i ON so.id = i.sales_order_id;
```

**Service Location:** `backend/services/sap-mock-adapter/kpi.js`

**Code Example:**
```javascript
async function calculateInvoiceCompletion(pool) {
  const result = await pool.query(`
    SELECT 
      COUNT(DISTINCT so.id) as total_orders,
      SUM(so.total_amount) as total_order_amount,
      SUM(i.amount) as total_invoiced_amount
    FROM sales_order so
    LEFT JOIN invoice i ON so.id = i.sales_order_id
  `);
  
  const { total_orders, total_order_amount, total_invoiced_amount } = result.rows[0];
  
  if (!total_order_amount || total_order_amount === 0) return 0;
  
  return {
    value: ((total_invoiced_amount / total_order_amount) * 100).toFixed(2),
    total_orders,
    invoiced_amount: (total_invoiced_amount || 0).toFixed(2),
    order_amount: total_order_amount.toFixed(2),
    pending_amount: ((total_order_amount - (total_invoiced_amount || 0))).toFixed(2),
    timestamp: new Date()
  };
}
```

**Update Frequency:** Every 24 hours

**Endpoint:** `GET /api/kpi/invoice-completion`

---

## Consolidated KPI Endpoint

**Endpoint:** `GET /api/kpi/all`

**Response:**
```json
{
  "asset_health_index": 87.50,
  "compliance_score": 93.20,
  "audit_readiness": 78.90,
  "maintenance_efficiency": 72.10,
  "supplier_risk_score": 88.40,
  "po_open_count": 5,
  "invoice_completion_rate": 91.50,
  "timestamp": "2026-06-07T14:35:00Z"
}
```

**Implementation:**
```javascript
async function getAllKPIs(pool) {
  const kpis = await Promise.all([
    calculateAssetHealth(pool),
    calculateComplianceScore(pool),
    calculateAuditReadiness(pool),
    calculateMaintenanceEfficiency(pool),
    calculateSupplierRiskScore(pool),
    calculatePOMetrics(pool),
    calculateInvoiceCompletion(pool)
  ]);
  
  return {
    asset_health_index: kpis[0].value,
    compliance_score: kpis[1].value,
    audit_readiness: kpis[2].value,
    maintenance_efficiency: kpis[3].value,
    supplier_risk_score: kpis[4].value,
    po_open_count: kpis[5].open_count,
    invoice_completion_rate: kpis[6].value,
    timestamp: new Date().toISOString(),
    details: {
      asset_health: kpis[0],
      compliance: kpis[1],
      audit: kpis[2],
      maintenance: kpis[3],
      supplier: kpis[4],
      po: kpis[5],
      invoice: kpis[6]
    }
  };
}
```

---

## KPI Snapshot Storage

**Purpose:** Historical KPI tracking for trends and reporting

**Table:** `kpi_snapshot`

**Stored Every:** 1 hour (scheduled job)

**Query:**
```javascript
async function storeKPISnapshot(pool, kpiData) {
  await pool.query(`
    INSERT INTO kpi_snapshot (
      asset_health_index,
      compliance_score,
      audit_readiness,
      maintenance_efficiency,
      supplier_risk_score,
      timestamp
    ) VALUES ($1, $2, $3, $4, $5, NOW())
  `, [
    kpiData.asset_health_index,
    kpiData.compliance_score,
    kpiData.audit_readiness,
    kpiData.maintenance_efficiency,
    kpiData.supplier_risk_score
  ]);
}
```

**Retrieve Historical:** `GET /api/kpi/history?days=7`

---

## Backend Service Integration

### Asset Service (`backend/services/asset-service/routes.js`)
```javascript
const express = require('express');
const router = express.Router();
const kpi = require('./kpi');

router.get('/api/kpi/asset-health', async (req, res) => {
  try {
    const result = await kpi.calculateAssetHealth(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/api/kpi/maintenance-efficiency', async (req, res) => {
  try {
    const result = await kpi.calculateMaintenanceEfficiency(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
```

### Compliance Service (`backend/services/compliance-service/routes.js`)
```javascript
router.get('/api/kpi/compliance-score', async (req, res) => {
  try {
    const result = await kpi.calculateComplianceScore(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
```

### Evidence Service (`backend/services/evidence-service/routes.js`)
```javascript
router.get('/api/kpi/audit-readiness', async (req, res) => {
  try {
    const result = await kpi.calculateAuditReadiness(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
```

### SAP Adapter (`backend/sap-mock-adapter/routes.js`)
```javascript
router.get('/api/kpi/supplier-risk', async (req, res) => {
  try {
    const result = await kpi.calculateSupplierRiskScore(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/api/kpi/po-metrics', async (req, res) => {
  try {
    const result = await kpi.calculatePOMetrics(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/api/kpi/invoice-completion', async (req, res) => {
  try {
    const result = await kpi.calculateInvoiceCompletion(req.app.get('pool'));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
```

---

## Frontend Integration (React Dashboard)

**Hook:** `useKPI.js`

```javascript
import { useEffect, useState } from 'react';

export function useKPI(refreshInterval = 30000) {
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    const fetchKPIs = async () => {
      try {
        const response = await fetch('/api/kpi/all');
        const data = await response.json();
        setKpis(data);
        setError(null);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    
    // Initial fetch
    fetchKPIs();
    
    // Set up polling
    const interval = setInterval(fetchKPIs, refreshInterval);
    
    return () => clearInterval(interval);
  }, [refreshInterval]);
  
  return { kpis, loading, error };
}
```

**Component Usage:**
```javascript
import { useKPI } from '../hooks/useKPI';

function KPIDashboard() {
  const { kpis, loading, error } = useKPI(30000); // 30 second refresh
  
  if (loading) return <div>Loading KPIs...</div>;
  if (error) return <div>Error: {error}</div>;
  
  return (
    <div className="kpi-grid">
      <KPICard 
        title="Asset Health Index" 
        value={kpis.asset_health_index} 
        unit="%" 
      />
      <KPICard 
        title="Compliance Score" 
        value={kpis.compliance_score} 
        unit="%" 
      />
      {/* ... more KPI cards ... */}
    </div>
  );
}
```

---

## Testing

**Unit Test Example:**
```javascript
// tests/kpi.test.js
const { calculateAssetHealth } = require('../services/asset-service/kpi');

describe('KPI Engine', () => {
  it('should calculate asset health correctly', async () => {
    const mockPool = {
      query: jest.fn().mockResolvedValue({
        rows: [{
          total_assets: 100,
          passed: 87,
          failed: 13
        }]
      })
    };
    
    const result = await calculateAssetHealth(mockPool);
    
    expect(result.value).toBe('87.00');
    expect(result.total_assets).toBe(100);
    expect(result.passed).toBe(87);
  });
});
```

