-- EnergyTrace360 Database Schema
-- PostgreSQL 14+

-- ============================================================================
-- ASSET INTEGRITY DOMAIN
-- ============================================================================

CREATE TABLE asset (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    location VARCHAR(255),
    supplier_id UUID,
    inspection_frequency_days INT DEFAULT 30,
    last_inspection_date TIMESTAMP,
    last_inspection_result VARCHAR(50),
    next_inspection_due TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100)
);

CREATE TABLE inspection (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES asset(id),
    inspection_date TIMESTAMP NOT NULL,
    result VARCHAR(50) NOT NULL,
    inspector_id VARCHAR(100),
    notes TEXT,
    anomaly_detected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- COMPLIANCE MANAGEMENT DOMAIN
-- ============================================================================

CREATE TABLE compliance_rule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    standard VARCHAR(50) NOT NULL,
    description TEXT,
    version VARCHAR(10),
    effective_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE control (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL REFERENCES compliance_rule(id),
    asset_id UUID NOT NULL REFERENCES asset(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    evidence_required BOOLEAN DEFAULT TRUE,
    status VARCHAR(50) NOT NULL,
    assigned_to VARCHAR(100),
    due_date DATE,
    reviewed_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE non_conformance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    control_id UUID NOT NULL REFERENCES control(id),
    description TEXT NOT NULL,
    severity VARCHAR(50) NOT NULL,
    identified_date TIMESTAMP NOT NULL,
    root_cause TEXT,
    status VARCHAR(50) NOT NULL,
    resolved_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE corrective_action (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nc_id UUID NOT NULL REFERENCES non_conformance(id),
    action_description TEXT NOT NULL,
    assigned_to VARCHAR(100) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    completion_date TIMESTAMP,
    approved_by VARCHAR(100),
    approved_date TIMESTAMP,
    evidence_id UUID,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- AUDIT EVIDENCE DOMAIN
-- ============================================================================

CREATE TABLE audit_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES asset(id),
    type VARCHAR(50) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    file_name VARCHAR(255),
    file_size BIGINT,
    version INT DEFAULT 1,
    status VARCHAR(50) NOT NULL,
    created_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE TABLE evidence_link (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    evidence_id UUID NOT NULL REFERENCES audit_evidence(id),
    control_id UUID NOT NULL REFERENCES control(id),
    link_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_package (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audit_date DATE NOT NULL,
    scope VARCHAR(255),
    evidence_ids JSONB NOT NULL,
    snapshot_hash VARCHAR(64) UNIQUE,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SAP MM SIMULATION
-- ============================================================================

CREATE TABLE supplier (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sap_id VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    country VARCHAR(2),
    rating DECIMAL(3,1) DEFAULT 0.0,
    certifications JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE material (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sap_id VARCHAR(20),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    supplier_id UUID REFERENCES supplier(id),
    lifespan_months INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ANALYTICS
-- ============================================================================

CREATE TABLE kpi_snapshot (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_health_index DECIMAL(5,2),
    compliance_score DECIMAL(5,2),
    audit_readiness DECIMAL(5,2),
    maintenance_efficiency DECIMAL(5,2),
    supplier_risk_score DECIMAL(5,2),
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_asset_status ON asset(status);
CREATE INDEX idx_inspection_asset_date ON inspection(asset_id, inspection_date DESC);
CREATE INDEX idx_control_status ON control(status);
CREATE INDEX idx_nc_status_severity ON non_conformance(status, severity);
CREATE INDEX idx_evidence_asset ON audit_evidence(asset_id);
CREATE INDEX idx_evidence_link_control ON evidence_link(control_id);
CREATE INDEX idx_kpi_snapshot_time ON kpi_snapshot(timestamp DESC);
