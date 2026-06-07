const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3002;

app.use(cors());
app.use(express.json());

// Mock Suppliers (SAP MM)
const suppliers = [
  { id: 'SUPP-001', sap_id: '1000001', name: 'GreenEnergy Ltd', country: 'DE', rating: 9.2, certifications: ['ISO 14001', 'ISO 45001', 'ISO 9001'] },
  { id: 'SUPP-002', sap_id: '1000002', name: 'IndustrialParts AG', country: 'CH', rating: 8.7, certifications: ['ISO 14001', 'ISO 9001'] },
  { id: 'SUPP-003', sap_id: '1000003', name: 'TechSupply Corp', country: 'US', rating: 7.5, certifications: ['ISO 9001'] },
  { id: 'SUPP-004', sap_id: '1000004', name: 'EuroParts BV', country: 'NL', rating: 8.9, certifications: ['ISO 14001', 'ISO 45001'] },
  { id: 'SUPP-005', sap_id: '1000005', name: 'AsiaManufacture Ltd', country: 'SG', rating: 7.2, certifications: ['ISO 9001'] },
  { id: 'SUPP-006', sap_id: '1000006', name: 'PrecisionTools GmbH', country: 'DE', rating: 9.0, certifications: ['ISO 14001', 'ISO 45001'] },
  { id: 'SUPP-007', sap_id: '1000007', name: 'GlobalComponents Inc', country: 'CA', rating: 8.1, certifications: ['ISO 9001'] },
  { id: 'SUPP-008', sap_id: '1000008', name: 'EcoSupplies SA', country: 'FR', rating: 8.8, certifications: ['ISO 14001'] },
  { id: 'SUPP-009', sap_id: '1000009', name: 'QualityFirst Ltd', country: 'UK', rating: 9.3, certifications: ['ISO 14001', 'ISO 45001', 'ISO 9001'] },
  { id: 'SUPP-010', sap_id: '1000010', name: 'StandardParts Ltd', country: 'SE', rating: 8.0, certifications: ['ISO 9001'] }
];

// Mock Materials (SAP MM)
const materials = [
  { id: 'MAT-001', sap_id: '300000001', name: 'Industrial Turbine Blade', category: 'EQUIPMENT', supplier_id: 'SUPP-001', lifespan_months: 24 },
  { id: 'MAT-002', sap_id: '300000002', name: 'Hydraulic Pump Unit', category: 'EQUIPMENT', supplier_id: 'SUPP-002', lifespan_months: 18 },
  { id: 'MAT-003', sap_id: '300000003', name: 'Compressor Filter', category: 'SPARE_PART', supplier_id: 'SUPP-003', lifespan_months: 6 },
  { id: 'MAT-004', sap_id: '300000004', name: 'Pressure Valve Assembly', category: 'EQUIPMENT', supplier_id: 'SUPP-004', lifespan_months: 36 },
  { id: 'MAT-005', sap_id: '300000005', name: 'Bearing Set', category: 'COMPONENT', supplier_id: 'SUPP-005', lifespan_months: 12 }
];

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'sap-mock-adapter' });
});

// ============================================================================
// SAP MM OData-style Mock Endpoints
// ============================================================================

// List Suppliers (OData simulation)
app.get('/sap/mm/suppliers', (req, res) => {
  res.json({
    d: {
      results: suppliers
    }
  });
});

// Get Supplier by ID
app.get('/sap/mm/suppliers/:id', (req, res) => {
  const supplier = suppliers.find(s => s.id === req.params.id);
  if (!supplier) {
    return res.status(404).json({ error: 'Supplier not found' });
  }
  res.json({
    d: {
      results: [supplier]
    }
  });
});

// List Materials (OData simulation)
app.get('/sap/mm/materials', (req, res) => {
  const { supplier_id } = req.query;
  const filtered = supplier_id
    ? materials.filter(m => m.supplier_id === supplier_id)
    : materials;
  res.json({
    d: {
      results: filtered
    }
  });
});

// Get Material by ID
app.get('/sap/mm/materials/:id', (req, res) => {
  const material = materials.find(m => m.id === req.params.id);
  if (!material) {
    return res.status(404).json({ error: 'Material not found' });
  }
  res.json({
    d: {
      results: [material]
    }
  });
});

// Link Asset to Material (Mock)
app.post('/sap/mm/asset-link', (req, res) => {
  const { asset_id, material_id, supplier_id } = req.body;
  res.status(201).json({
    asset_id,
    material_id,
    supplier_id,
    linked_at: new Date().toISOString(),
    message: 'Asset linked to SAP MM material'
  });
});

// Get Supplier Risk Score (Mock Calculation)
app.get('/sap/mm/supplier-risk', (req, res) => {
  const highRated = suppliers.filter(s => s.rating >= 8.5).length;
  const score = ((highRated / suppliers.length) * 100).toFixed(1);
  res.json({
    supplier_risk_score: parseFloat(score),
    high_rated: highRated,
    total: suppliers.length
  });
});

// Error Handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal Server Error', message: err.message });
});

// Start Server
app.listen(PORT, () => {
  console.log(`SAP Mock Adapter running on port ${PORT}`);
});

module.exports = app;
