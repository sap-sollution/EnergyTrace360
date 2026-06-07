-- EnergyTrace360 Seed Data
-- Initial data for development and testing

-- ============================================================================
-- SAP MM SIMULATION: Suppliers
-- ============================================================================

INSERT INTO supplier (sap_id, name, country, rating, certifications) VALUES
('1000001', 'GreenEnergy Ltd', 'DE', 9.2, '["ISO 14001", "ISO 45001", "ISO 9001"]'::jsonb),
('1000002', 'IndustrialParts AG', 'CH', 8.7, '["ISO 14001", "ISO 9001"]'::jsonb),
('1000003', 'TechSupply Corp', 'US', 7.5, '["ISO 9001"]'::jsonb),
('1000004', 'EuroParts BV', 'NL', 8.9, '["ISO 14001", "ISO 45001"]'::jsonb),
('1000005', 'AsiaManufacture Ltd', 'SG', 7.2, '["ISO 9001"]'::jsonb),
('1000006', 'PrecisionTools GmbH', 'DE', 9.0, '["ISO 14001", "ISO 45001"]'::jsonb),
('1000007', 'GlobalComponents Inc', 'CA', 8.1, '["ISO 9001"]'::jsonb),
('1000008', 'EcoSupplies SA', 'FR', 8.8, '["ISO 14001"]'::jsonb),
('1000009', 'QualityFirst Ltd', 'UK', 9.3, '["ISO 14001", "ISO 45001", "ISO 9001"]'::jsonb),
('1000010', 'StandardParts Ltd', 'SE', 8.0, '["ISO 9001"]'::jsonb);

-- ============================================================================
-- SAP MM SIMULATION: Materials
-- ============================================================================

INSERT INTO material (sap_id, name, category, supplier_id, lifespan_months) VALUES
('300000001', 'Industrial Turbine Blade', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000001'), 24),
('300000002', 'Hydraulic Pump Unit', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000002'), 18),
('300000003', 'Compressor Filter', 'SPARE_PART', (SELECT id FROM supplier WHERE sap_id = '1000003'), 6),
('300000004', 'Pressure Valve Assembly', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000004'), 36),
('300000005', 'Bearing Set', 'COMPONENT', (SELECT id FROM supplier WHERE sap_id = '1000005'), 12);

-- ============================================================================
-- ASSET INTEGRITY: Assets
-- ============================================================================

INSERT INTO asset (name, type, status, location, inspection_frequency_days, created_by) VALUES
('Turbine Unit 1', 'EQUIPMENT', 'ACTIVE', 'Plant A - Main Hall', 30, 'admin'),
('Compressor Unit 2', 'EQUIPMENT', 'ACTIVE', 'Plant A - Comp Building', 30, 'admin'),
('Pump Station 3', 'EQUIPMENT', 'ACTIVE', 'Plant B - Hydraulics', 14, 'admin'),
('Valve Assembly 4', 'EQUIPMENT', 'MAINTENANCE', 'Plant A - Pipeline', 60, 'admin'),
('Generator Unit 1', 'EQUIPMENT', 'ACTIVE', 'Plant C - Power', 45, 'admin'),
('Tank Storage A1', 'TANK', 'ACTIVE', 'Plant B - Storage', 90, 'admin');

-- ============================================================================
-- ASSET INTEGRITY: Inspections
-- ============================================================================

INSERT INTO inspection (asset_id, inspection_date, result, inspector_id, notes, anomaly_detected) VALUES
((SELECT id FROM asset WHERE name = 'Turbine Unit 1'), '2026-06-05T10:30:00Z', 'PASS', 'INS-001', 'Equipment running normally. Vibration within limits.', FALSE),
((SELECT id FROM asset WHERE name = 'Compressor Unit 2'), '2026-06-04T14:15:00Z', 'PASS', 'INS-002', 'Pressure readings normal. No anomalies detected.', FALSE),
((SELECT id FROM asset WHERE name = 'Pump Station 3'), '2026-06-03T09:45:00Z', 'FAIL', 'INS-001', 'Unusual vibration detected. Requires investigation.', TRUE),
((SELECT id FROM asset WHERE name = 'Generator Unit 1'), '2026-06-02T11:20:00Z', 'PASS', 'INS-003', 'Performance metrics normal. Output stable.', FALSE),
((SELECT id FROM asset WHERE name = 'Tank Storage A1'), '2026-06-01T08:00:00Z', 'PASS', 'INS-002', 'Storage tank structural integrity verified.', FALSE);

-- Update asset inspection status
UPDATE asset SET 
    last_inspection_date = (SELECT MAX(inspection_date) FROM inspection WHERE asset.id = inspection.asset_id),
    last_inspection_result = (SELECT result FROM inspection WHERE asset.id = inspection.asset_id ORDER BY inspection_date DESC LIMIT 1),
    next_inspection_due = (SELECT MAX(inspection_date) FROM inspection WHERE asset.id = inspection.asset_id) + (inspection_frequency_days || ' days')::INTERVAL;

-- ============================================================================
-- COMPLIANCE MANAGEMENT: Compliance Rules
-- ============================================================================

INSERT INTO compliance_rule (name, standard, description, version, effective_date) VALUES
('ISO 14001:2015 Environmental Management', 'ISO-14001', 'International standard for environmental management systems', '2015', '2023-01-01'),
('Asset Inspection & Maintenance', 'ASSET-MGMT', 'Enterprise framework for asset lifecycle management', '1.0', '2023-01-01');

-- ============================================================================
-- COMPLIANCE MANAGEMENT: Controls
-- ============================================================================

INSERT INTO control (rule_id, asset_id, name, description, evidence_required, status, assigned_to, due_date) VALUES
((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'), 
 (SELECT id FROM asset WHERE name = 'Turbine Unit 1'),
 'Routine Inspection Documentation',
 'All routine inspections must be documented and archived',
 TRUE, 'MET', 'john.manager@company.com', '2026-12-31'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Compressor Unit 2'),
 'Maintenance Record Keeping',
 'Complete maintenance records for all equipment',
 TRUE, 'MET', 'jane.supervisor@company.com', '2026-12-31'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Pump Station 3'),
 'Environmental Risk Assessment',
 'Annual environmental risk assessment required',
 TRUE, 'NOT_MET', 'bob.compliance@company.com', '2026-06-30'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Tank Storage A1'),
 'Hazardous Material Documentation',
 'All hazardous materials in storage documented',
 TRUE, 'MET', 'alice.ehs@company.com', '2026-12-31'),

((SELECT id FROM compliance_rule WHERE standard = 'ASSET-MGMT'),
 (SELECT id FROM asset WHERE name = 'Generator Unit 1'),
 'Equipment Performance Tracking',
 'Continuous performance metrics collection and analysis',
 TRUE, 'MET', 'carlos.ops@company.com', '2026-09-30');

-- ============================================================================
-- COMPLIANCE MANAGEMENT: Non-Conformances
-- ============================================================================

INSERT INTO non_conformance (control_id, description, severity, identified_date, status) VALUES
((SELECT id FROM control WHERE name = 'Environmental Risk Assessment'),
 'Annual environmental risk assessment not completed for Pump Station 3',
 'HIGH', '2026-06-01T08:00:00Z', 'OPEN'),

((SELECT id FROM control WHERE name = 'Routine Inspection Documentation'),
 'Missing inspection report for May 2026',
 'MEDIUM', '2026-06-02T10:30:00Z', 'IN_PROGRESS');

-- ============================================================================
-- AUDIT EVIDENCE: Evidence
-- ============================================================================

INSERT INTO audit_evidence (asset_id, type, file_url, file_name, file_size, status, created_by) VALUES
((SELECT id FROM asset WHERE name = 'Turbine Unit 1'), 'INSPECTION', '/evidence/turbine-inspection-2026-06-05.pdf', 'turbine-inspection-2026-06-05.pdf', 2048576, 'FINAL', 'INS-001'),
((SELECT id FROM asset WHERE name = 'Compressor Unit 2'), 'MAINTENANCE', '/evidence/compressor-maintenance-log.pdf', 'compressor-maintenance-log.pdf', 1024000, 'FINAL', 'admin'),
((SELECT id FROM asset WHERE name = 'Tank Storage A1'), 'DOCUMENT', '/evidence/hazmat-inventory-2026-Q2.xlsx', 'hazmat-inventory-2026-Q2.xlsx', 512000, 'FINAL', 'admin');

-- ============================================================================
-- AUDIT EVIDENCE: Evidence Links
-- ============================================================================

INSERT INTO evidence_link (evidence_id, control_id, link_type) VALUES
((SELECT id FROM audit_evidence WHERE file_name = 'turbine-inspection-2026-06-05.pdf'),
 (SELECT id FROM control WHERE name = 'Routine Inspection Documentation'), 'SUPPORTS'),

((SELECT id FROM audit_evidence WHERE file_name = 'compressor-maintenance-log.pdf'),
 (SELECT id FROM control WHERE name = 'Maintenance Record Keeping'), 'SUPPORTS'),

((SELECT id FROM audit_evidence WHERE file_name = 'hazmat-inventory-2026-Q2.xlsx'),
 (SELECT id FROM control WHERE name = 'Hazardous Material Documentation'), 'SUPPORTS');

-- ============================================================================
-- ANALYTICS: KPI Snapshots
-- ============================================================================

INSERT INTO kpi_snapshot (asset_health_index, compliance_score, audit_readiness, maintenance_efficiency, supplier_risk_score, timestamp) VALUES
(85.7, 92.5, 88.3, 72.1, 87.5, CURRENT_TIMESTAMP),
(84.2, 91.8, 86.5, 70.5, 87.0, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(82.5, 90.2, 84.1, 68.3, 85.2, CURRENT_TIMESTAMP - INTERVAL '2 days'),
(81.0, 89.5, 82.0, 66.7, 84.5, CURRENT_TIMESTAMP - INTERVAL '3 days'),
(80.3, 88.9, 80.5, 65.2, 84.0, CURRENT_TIMESTAMP - INTERVAL '4 days');
