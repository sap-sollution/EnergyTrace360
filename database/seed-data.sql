-- EnergyTrace360 Seed Data

-- ============================================================================
-- SUPPLIERS (SAP MM)
-- ============================================================================

INSERT INTO supplier (name, sap_id, country, rating, certifications) VALUES
('GreenEnergy Ltd', '1000001', 'DE', 9.2, '["ISO 14001", "ISO 45001", "ISO 9001"]'),
('IndustrialParts AG', '1000002', 'CH', 8.7, '["ISO 14001", "ISO 9001"]'),
('TechSupply Corp', '1000003', 'US', 7.5, '["ISO 9001"]'),
('EuroParts BV', '1000004', 'NL', 8.9, '["ISO 14001", "ISO 45001"]'),
('AsiaManufacture Ltd', '1000005', 'SG', 7.2, '["ISO 9001"]'),
('PrecisionTools GmbH', '1000006', 'DE', 9.0, '["ISO 14001", "ISO 45001"]'),
('GlobalComponents Inc', '1000007', 'CA', 8.1, '["ISO 9001"]'),
('EcoSupplies SA', '1000008', 'FR', 8.8, '["ISO 14001"]'),
('QualityFirst Ltd', '1000009', 'UK', 9.3, '["ISO 14001", "ISO 45001", "ISO 9001"]'),
('StandardParts Ltd', '1000010', 'SE', 8.0, '["ISO 9001"]');

-- ============================================================================
-- MATERIALS (SAP MM)
-- ============================================================================

INSERT INTO material (name, sap_id, category, supplier_id, lifespan_months) VALUES
('Industrial Turbine Blade', '300000001', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000001'), 24),
('Hydraulic Pump Unit', '300000002', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000002'), 18),
('Compressor Filter', '300000003', 'SPARE_PART', (SELECT id FROM supplier WHERE sap_id = '1000003'), 6),
('Pressure Valve Assembly', '300000004', 'EQUIPMENT', (SELECT id FROM supplier WHERE sap_id = '1000004'), 36),
('Bearing Set', '300000005', 'COMPONENT', (SELECT id FROM supplier WHERE sap_id = '1000005'), 12),
('Gasket Seal Kit', '300000006', 'SPARE_PART', (SELECT id FROM supplier WHERE sap_id = '1000006'), 3),
('Motor Coupling', '300000007', 'COMPONENT', (SELECT id FROM supplier WHERE sap_id = '1000007'), 24);

-- ============================================================================
-- ASSETS
-- ============================================================================

INSERT INTO asset (name, type, status, location, supplier_id, inspection_frequency_days) VALUES
('Turbine Unit 1', 'EQUIPMENT', 'ACTIVE', 'Plant A - Main Hall', (SELECT id FROM supplier WHERE sap_id = '1000001'), 30),
('Compressor Unit 2', 'EQUIPMENT', 'ACTIVE', 'Plant A - Comp Building', (SELECT id FROM supplier WHERE sap_id = '1000002'), 30),
('Pump Station 3', 'EQUIPMENT', 'ACTIVE', 'Plant B - Hydraulics', (SELECT id FROM supplier WHERE sap_id = '1000003'), 14),
('Valve Assembly 4', 'EQUIPMENT', 'MAINTENANCE', 'Plant A - Pipeline', (SELECT id FROM supplier WHERE sap_id = '1000004'), 60),
('Generator Unit 1', 'EQUIPMENT', 'ACTIVE', 'Plant C - Power', (SELECT id FROM supplier WHERE sap_id = '1000005'), 45),
('Tank Storage A1', 'TANK', 'ACTIVE', 'Plant B - Storage', (SELECT id FROM supplier WHERE sap_id = '1000006'), 90),
('Heat Exchanger 5', 'EQUIPMENT', 'ACTIVE', 'Plant C - Thermal', (SELECT id FROM supplier WHERE sap_id = '1000007'), 60);

-- ============================================================================
-- COMPLIANCE RULES (ISO 14001:2015)
-- ============================================================================

INSERT INTO compliance_rule (name, standard, description, version, effective_date) VALUES
('ISO 14001:2015 Environmental Management', 'ISO-14001', 'International standard for environmental management systems', '2015', '2023-01-01'),
('Asset Inspection & Maintenance', 'ISO-14001', 'Compliance framework for asset inspection schedules', '1.0', '2023-01-01');

-- ============================================================================
-- CONTROLS (ISO 14001)
-- ============================================================================

INSERT INTO control (rule_id, asset_id, name, description, evidence_required, status, assigned_to, due_date) VALUES
((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'), 
 (SELECT id FROM asset WHERE name = 'Turbine Unit 1'),
 'Routine Inspection Documentation',
 'All routine inspections must be documented and filed',
 TRUE, 'MET', 'john.manager@company.com', '2026-12-31'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Compressor Unit 2'),
 'Maintenance Record Keeping',
 'Complete maintenance records must be maintained for all equipment',
 TRUE, 'MET', 'jane.supervisor@company.com', '2026-12-31'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Pump Station 3'),
 'Environmental Risk Assessment',
 'Annual environmental risk assessment required',
 TRUE, 'NOT_MET', 'bob.compliance@company.com', '2026-06-30'),

((SELECT id FROM compliance_rule WHERE standard = 'ISO-14001'),
 (SELECT id FROM asset WHERE name = 'Tank Storage A1'),
 'Hazardous Material Documentation',
 'All hazardous materials in storage must be documented',
 TRUE, 'MET', 'alice.ehs@company.com', '2026-12-31');

-- ============================================================================
-- INSPECTIONS
-- ============================================================================

INSERT INTO inspection (asset_id, inspection_date, result, inspector_id, notes, anomaly_detected) VALUES
((SELECT id FROM asset WHERE name = 'Turbine Unit 1'), 
 '2026-06-05T10:30:00Z', 'PASS', 'INS-001', 'Equipment running normally. Vibration within limits.', FALSE),

((SELECT id FROM asset WHERE name = 'Compressor Unit 2'),
 '2026-06-04T14:15:00Z', 'PASS', 'INS-002', 'Pressure readings normal. No anomalies detected.', FALSE),

((SELECT id FROM asset WHERE name = 'Pump Station 3'),
 '2026-06-03T09:45:00Z', 'FAIL', 'INS-001', 'Unusual vibration detected. Requires further investigation.', TRUE),

((SELECT id FROM asset WHERE name = 'Generator Unit 1'),
 '2026-06-02T11:20:00Z', 'PASS', 'INS-003', 'Performance metrics normal. Output stable.', FALSE);

-- ============================================================================
-- NON-CONFORMANCES
-- ============================================================================

INSERT INTO non_conformance (control_id, description, severity, identified_date, status) VALUES
((SELECT id FROM control WHERE name = 'Environmental Risk Assessment'),
 'Annual environmental risk assessment not completed for Pump Station 3',
 'HIGH', '2026-06-01T08:00:00Z', 'OPEN'),

((SELECT id FROM control WHERE name = 'Routine Inspection Documentation'),
 'Missing inspection report for month of May',
 'MEDIUM', '2026-06-02T10:30:00Z', 'IN_PROGRESS');

-- ============================================================================
-- KPI SNAPSHOT
-- ============================================================================

INSERT INTO kpi_snapshot (asset_health_index, compliance_score, audit_readiness, maintenance_efficiency, supplier_risk_score, timestamp) VALUES
(85.7, 92.5, 88.3, 72.1, 87.5, CURRENT_TIMESTAMP),
(84.2, 91.8, 86.5, 70.5, 87.0, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(82.5, 90.2, 84.1, 68.3, 85.2, CURRENT_TIMESTAMP - INTERVAL '2 days');
