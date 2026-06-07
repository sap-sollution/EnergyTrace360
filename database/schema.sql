-- EnergyTrace360 Database Schema
-- PostgreSQL 14+
-- 7 Core Entities for Asset Integrity & Compliance Management

-- ============================================================================
-- ASSET INTEGRITY DOMAIN (Entity 1: Asset)
-- ============================================================================

CREATE TABLE asset (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    location VARCHAR(255),
    inspection_frequency_days INT DEFAULT 30,
    last_inspection_date TIMESTAMP,
    last_inspection_result VARCHAR(50),
    next_inspection_due TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    CHECK (status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE')),
    CHECK (last_inspection_result IS NULL OR last_inspection_result IN ('PASS', 'FAIL', 'INCONCLUSIVE'))
);

CREATE INDEX idx_asset_status ON asset(status);
CREATE INDEX idx_asset_next_due ON asset(next_inspection_due);

-- ============================================================================
-- ASSET INTEGRITY DOMAIN (Entity 2: Inspection)
-- ============================================================================

CREATE TABLE inspection (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,
    inspection_date TIMESTAMP NOT NULL,
    result VARCHAR(50) NOT NULL,
    inspector_id VARCHAR(100),
    notes TEXT,
    anomaly_detected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (result IN ('PASS', 'FAIL', 'INCONCLUSIVE'))
);

CREATE INDEX idx_inspection_asset_date ON inspection(asset_id, inspection_date DESC);
CREATE INDEX idx_inspection_result ON inspection(result);

-- ============================================================================
-- COMPLIANCE MANAGEMENT DOMAIN (Entity 3: ComplianceRule)
-- ============================================================================

CREATE TABLE compliance_rule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    standard VARCHAR(50) NOT NULL,
    description TEXT,
    version VARCHAR(10),
    effective_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(standard, version)
);

CREATE INDEX idx_compliance_rule_standard ON compliance_rule(standard);

-- ============================================================================
-- COMPLIANCE MANAGEMENT DOMAIN (Entity 4: Control)
-- ============================================================================

CREATE TABLE control (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL REFERENCES compliance_rule(id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    evidence_required BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) NOT NULL,
    assigned_to VARCHAR(100),
    due_date DATE,
    reviewed_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('MET', 'NOT_MET', 'PENDING'))
);

CREATE INDEX idx_control_rule ON control(rule_id);
CREATE INDEX idx_control_asset ON control(asset_id);
CREATE INDEX idx_control_status ON control(status);

-- ============================================================================
-- COMPLIANCE MANAGEMENT DOMAIN (Entity 5: NonConformance)
-- ============================================================================

CREATE TABLE non_conformance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES control(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL,
    identified_date TIMESTAMP NOT NULL,
    root_cause TEXT,
    status VARCHAR(50) NOT NULL,
    resolved_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED'))
);

CREATE INDEX idx_nc_control ON non_conformance(control_id);
CREATE INDEX idx_nc_severity_status ON non_conformance(severity, status);

-- ============================================================================
-- AUDIT EVIDENCE DOMAIN (Entity 6: AuditEvidence)
-- ============================================================================

CREATE TABLE audit_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES asset(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    version INT DEFAULT 1,
    status VARCHAR(50) NOT NULL,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    CHECK (type IN ('DOCUMENT', 'INSPECTION', 'TEST', 'PHOTO', 'REPORT')),
    CHECK (status IN ('DRAFT', 'FINAL', 'ARCHIVED'))
);

CREATE INDEX idx_evidence_asset ON audit_evidence(asset_id);
CREATE INDEX idx_evidence_status ON audit_evidence(status);
CREATE INDEX idx_evidence_created ON audit_evidence(created_at DESC);

-- ============================================================================
-- AUDIT EVIDENCE DOMAIN (Entity 7: KPISnapshot)
-- ============================================================================

CREATE TABLE kpi_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_health_index DECIMAL(5,2),
    compliance_score DECIMAL(5,2),
    audit_readiness DECIMAL(5,2),
    maintenance_efficiency DECIMAL(5,2),
    supplier_risk_score DECIMAL(5,2),
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (asset_health_index >= 0 AND asset_health_index <= 100),
    CHECK (compliance_score >= 0 AND compliance_score <= 100),
    CHECK (audit_readiness >= 0 AND audit_readiness <= 100),
    CHECK (maintenance_efficiency >= 0 AND maintenance_efficiency <= 100),
    CHECK (supplier_risk_score >= 0 AND supplier_risk_score <= 100)
);

CREATE INDEX idx_kpi_timestamp ON kpi_snapshot(timestamp DESC);

-- ============================================================================
-- SAP MM SIMULATION (Support Tables)
-- ============================================================================

CREATE TABLE supplier (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sap_id VARCHAR(20) UNIQUE,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(2),
    rating DECIMAL(3,1) DEFAULT 0.0,
    certifications JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (rating >= 0 AND rating <= 10)
);

CREATE INDEX idx_supplier_rating ON supplier(rating DESC);

CREATE TABLE material (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sap_id VARCHAR(20) UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    supplier_id UUID REFERENCES supplier(id),
    lifespan_months INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_material_supplier ON material(supplier_id);

-- ============================================================================
-- LINKING EVIDENCE TO CONTROLS (Many-to-Many)
-- ============================================================================

CREATE TABLE evidence_link (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evidence_id UUID NOT NULL REFERENCES audit_evidence(id) ON DELETE CASCADE,
    control_id UUID NOT NULL REFERENCES control(id) ON DELETE CASCADE,
    link_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(evidence_id, control_id),
    CHECK (link_type IN ('SUPPORTS', 'CONTRADICTS', 'CLARIFIES'))
);

CREATE INDEX idx_evidence_link_control ON evidence_link(control_id);
CREATE INDEX idx_evidence_link_evidence ON evidence_link(evidence_id);

-- ============================================================================
-- CORRECTIVE ACTIONS (Support Table)
-- ============================================================================

CREATE TABLE corrective_action (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nc_id UUID NOT NULL REFERENCES non_conformance(id) ON DELETE CASCADE,
    action_description TEXT NOT NULL,
    assigned_to VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    completion_date TIMESTAMP,
    approved_by VARCHAR(100),
    approved_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('OPEN', 'IN_PROGRESS', 'COMPLETED'))
);

CREATE INDEX idx_ca_nc ON corrective_action(nc_id);
CREATE INDEX idx_ca_status ON corrective_action(status);

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    user_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE'))
);

CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at DESC);

-- ============================================================================
-- VIEWS FOR DASHBOARD QUERIES
-- ============================================================================

CREATE VIEW asset_inspection_summary AS
SELECT 
    a.id,
    a.name,
    a.status,
    COUNT(i.id) as total_inspections,
    SUM(CASE WHEN i.result = 'PASS' THEN 1 ELSE 0 END) as passed_inspections,
    SUM(CASE WHEN i.result = 'FAIL' THEN 1 ELSE 0 END) as failed_inspections,
    a.last_inspection_date,
    a.last_inspection_result,
    a.next_inspection_due
FROM asset a
LEFT JOIN inspection i ON a.id = i.asset_id
GROUP BY a.id, a.name, a.status, a.last_inspection_date, a.last_inspection_result, a.next_inspection_due;

CREATE VIEW compliance_status_summary AS
SELECT 
    c.id,
    c.name,
    c.status,
    c.rule_id,
    COUNT(el.id) as evidence_count,
    c.assigned_to,
    c.due_date
FROM control c
LEFT JOIN evidence_link el ON c.id = el.control_id
GROUP BY c.id, c.name, c.status, c.rule_id, c.assigned_to, c.due_date;

CREATE VIEW non_conformance_summary AS
SELECT 
    nc.id,
    nc.control_id,
    c.name as control_name,
    nc.severity,
    nc.status,
    nc.identified_date,
    COUNT(ca.id) as corrective_action_count
FROM non_conformance nc
JOIN control c ON nc.control_id = c.id
LEFT JOIN corrective_action ca ON nc.id = ca.nc_id
GROUP BY nc.id, nc.control_id, c.name, nc.severity, nc.status, nc.identified_date;
