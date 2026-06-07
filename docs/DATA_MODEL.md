# EnergyTrace360 - Data Model

## 🧱 Entity-Relationship Diagram

```
Asset Domain:
┌─────────────┐      ┌──────────────┐
│   Asset     │ 1──∞ │ Inspection   │
├─────────────┤      ├──────────────┤
│ id (PK)     │      │ id (PK)      │
│ name        │      │ asset_id(FK) │
│ type        │      │ date         │
│ status      │      │ result       │
│ location    │      │ notes        │
│ supplier_id │      │ created_at   │
│ created_at  │      └──────────────┘
└──────┬──────┘
       │
       └─────────────────────────────┐
                                    │
Compliance Domain:                 │
┌──────────────────┐               │
│ ComplianceRule   │               │
├──────────────────┤               │
│ id (PK)          │               │
│ name             │               │
│ standard         │               │
│ description      │               │
│ severity         │               │
│ created_at       │               │
└────────┬─────────┘               │
         │                         │
    1──∞ │                         │
┌─────────────────┐                │
│ Control         │                │
├─────────────────┤                │
│ id (PK)         │                │
│ rule_id (FK)    │                │
│ asset_id (FK)───────────────────┘
│ status          │
│ expected_by     │
│ created_at      │
└────────┬────────┘
         │
    1──∞ │
┌──────────────────────┐
│ NonConformance       │
├──────────────────────┤
│ id (PK)              │
│ control_id (FK)      │
│ description          │
│ severity             │
│ created_at           │
└────────┬─────────────┘
         │
    1──∞ │
┌──────────────────────┐
│ CorrectiveAction     │
├──────────────────────┤
│ id (PK)              │
│ nc_id (FK)           │
│ action_description   │
│ assigned_to          │
│ due_date             │
│ status               │
│ created_at           │
└──────────────────────┘

Evidence Domain:
┌─────────────────┐        ┌──────────────────┐
│ AuditEvidence   │ 1────∞ │ EvidenceLink     │
├─────────────────┤        ├──��───────────────┤
│ id (PK)         │        │ id (PK)          │
│ asset_id (FK)   │        │ evidence_id (FK) │
│ type            │        │ control_id (FK)  │
│ file_url        │        │ link_type        │
│ version         │        │ created_at       │
│ created_at      │        └──────────────────┘
│ updated_at      │
│ created_by      │
└────────┬────────┘
         │
    1──∞ │
┌─────────────────────┐
│ AuditPackage        │
├─────────────────────┤
│ id (PK)             │
│ audit_date          │
│ evidence_ids (JSON) │
│ snapshot            │
│ created_at          │
│ immutable_hash      │
└─────────────────────┘

Support Entities:
┌──────────────┐        ┌──────────────┐
│  Supplier    │ 1────∞ │   Material   │
├──────────────┤        ├──────────────┤
│ id (PK)      │        │ id (PK)      │
│ name         │        │ name         │
│ country      │        │ category     │
│ rating       │        │ supplier_id  │
│ created_at   │        │ created_at   │
└──────────────┘        └──────────────┘

Analytics:
┌──────────────────┐
│ KPISnapshot      │
├──────────────────┤
│ id (PK)          │
│ asset_health     │
│ compliance_score │
│ audit_readiness  │
│ maint_efficiency │
│ supplier_risk    │
│ timestamp        │
│ created_at       │
└──────────────────┘
```

---

## 📋 Core Entities - Detailed Definition

### Asset Domain

#### Asset
**Purpose:** Root aggregate for asset integrity domain

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| name | VARCHAR(255) | NOT NULL | Asset name (e.g., "Turbine Unit 3") |
| type | VARCHAR(50) | NOT NULL | Asset type (equipment, tank, valve, etc.) |
| status | ENUM | NOT NULL | ACTIVE / INACTIVE / MAINTENANCE |
| location | VARCHAR(255) | | Physical location in facility |
| supplier_id | UUID | FK | Link to SAP MM supplier (mock) |
| last_inspection_date | TIMESTAMP | | Date of most recent inspection |
| last_inspection_result | ENUM | | PASS / FAIL / PENDING |
| inspection_frequency_days | INT | DEFAULT 30 | How often to inspect (days) |
| next_inspection_due | TIMESTAMP | COMPUTED | Calculated field |
| created_at | TIMESTAMP | NOT NULL | Record creation timestamp |
| updated_at | TIMESTAMP | | Last update timestamp |
| created_by | VARCHAR(100) | | User who created |

**Business Rules:**
- status cannot be MAINTENANCE and ACTIVE simultaneously
- inspection_frequency_days must be > 0
- next_inspection_due = last_inspection_date + inspection_frequency_days

---

#### Inspection
**Purpose:** Record of asset inspection event

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| asset_id | UUID | FK → Asset | Which asset was inspected |
| inspection_date | TIMESTAMP | NOT NULL | When inspection occurred |
| result | ENUM | NOT NULL | PASS / FAIL / INCONCLUSIVE |
| inspector_id | VARCHAR(100) | | Who performed inspection |
| notes | TEXT | | Detailed findings |
| anomaly_detected | BOOLEAN | DEFAULT FALSE | Deviation from normal pattern |
| created_at | TIMESTAMP | NOT NULL | When record created |

**Business Rules:**
- inspection_date cannot be in future
- result = FAIL triggers automatic compliance alert
- anomaly_detected = TRUE if deviation > threshold from historical avg

---

### Compliance Management Domain

#### ComplianceRule
**Purpose:** Top-level compliance standard and framework

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| name | VARCHAR(255) | NOT NULL | Rule name (e.g., "ISO 14001:2015") |
| standard | VARCHAR(50) | NOT NULL | Standard code |
| description | TEXT | | What this standard covers |
| version | VARCHAR(10) | | Standard version |
| effective_date | DATE | | When rule became active |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Business Rules:**
- standard must be recognized (ISO 14001, CSRD, etc.)
- Multiple rules can coexist
- Version tracking for regulatory updates

---

#### Control
**Purpose:** Individual control within compliance rule

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| rule_id | UUID | FK → ComplianceRule | Parent rule |
| asset_id | UUID | FK → Asset | Which asset is controlled |
| name | VARCHAR(255) | NOT NULL | Control name |
| description | TEXT | | What must be done |
| evidence_required | BOOLEAN | DEFAULT TRUE | Must have evidence |
| status | ENUM | NOT NULL | MET / NOT_MET / PENDING |
| assigned_to | VARCHAR(100) | | Owner of this control |
| due_date | DATE | | When compliance needed |
| reviewed_date | TIMESTAMP | | Last review date |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Business Rules:**
- status = NOT_MET if evidence missing AND due_date passed
- Control cannot be MET without evidence (if evidence_required=true)
- reviewed_date must not be more than 30 days old

---

#### NonConformance
**Purpose:** Record of control violation

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| control_id | UUID | FK → Control | Which control failed |
| description | TEXT | NOT NULL | Why control not met |
| severity | ENUM | NOT NULL | CRITICAL / HIGH / MEDIUM / LOW |
| identified_date | TIMESTAMP | NOT NULL | When discovered |
| root_cause | TEXT | | Why it happened |
| status | ENUM | NOT NULL | OPEN / IN_PROGRESS / RESOLVED |
| resolved_date | TIMESTAMP | | When closed |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Business Rules:**
- CRITICAL severity must have corrective action within 24 hours
- status = RESOLVED only when corrective action approved AND closed
- resolved_date must be after identified_date

---

#### CorrectiveAction
**Purpose:** Action plan to fix non-conformance

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| nc_id | UUID | FK → NonConformance | Which NC this fixes |
| action_description | TEXT | NOT NULL | What will be done |
| assigned_to | VARCHAR(100) | NOT NULL | Who is responsible |
| due_date | DATE | NOT NULL | When must be complete |
| status | ENUM | NOT NULL | OPEN / IN_PROGRESS / COMPLETED |
| completion_date | TIMESTAMP | | When actually completed |
| approved_by | VARCHAR(100) | | Who approved completion |
| approved_date | TIMESTAMP | | Approval date |
| evidence_id | UUID | FK → AuditEvidence | Supporting proof |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Business Rules:**
- due_date must be within 30 days of NC identified_date
- status = COMPLETED requires approval before final close
- NC can have multiple corrective actions

---

### Audit Evidence Domain

#### AuditEvidence
**Purpose:** Central repository for compliance evidence

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| asset_id | UUID | FK → Asset | Related asset |
| type | ENUM | NOT NULL | DOCUMENT / INSPECTION / TEST / PHOTO / REPORT |
| file_url | VARCHAR(255) | NOT NULL | S3 or local storage path |
| file_name | VARCHAR(255) | | Original file name |
| file_size | BIGINT | | File size in bytes |
| version | INT | DEFAULT 1 | Version number |
| status | ENUM | NOT NULL | DRAFT / FINAL / ARCHIVED |
| created_by | VARCHAR(100) | NOT NULL | Who uploaded |
| created_at | TIMESTAMP | NOT NULL | Upload date |
| updated_at | TIMESTAMP | | Last modified |
| expires_at | TIMESTAMP | | Retention policy |

**Business Rules:**
- type determines how evidence is processed
- version increments on update (immutable history)
- status = FINAL cannot be modified (audit trail requirement)
- expires_at drives archival process

---

#### EvidenceLink
**Purpose:** Link evidence to controls (many-to-many)

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| evidence_id | UUID | FK → AuditEvidence | Evidence record |
| control_id | UUID | FK → Control | Related control |
| link_type | ENUM | NOT NULL | SUPPORTS / CONTRADICTS / CLARIFIES |
| created_at | TIMESTAMP | NOT NULL | When linked |

**Business Rules:**
- One evidence can support multiple controls
- link_type determines how evidence relates to control
- Removing link does not delete evidence (immutable)

---

#### AuditPackage
**Purpose:** Immutable snapshot of evidence for audit

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| audit_date | DATE | NOT NULL | When audit conducted |
| scope | VARCHAR(255) | | What was audited |
| evidence_ids | JSON | NOT NULL | Array of evidence IDs (snapshot) |
| snapshot_hash | VARCHAR(64) | UNIQUE | SHA256 hash (integrity check) |
| status | ENUM | NOT NULL | PREPARED / SUBMITTED / ACCEPTED / ARCHIVED |
| created_at | TIMESTAMP | NOT NULL | When package created |

**Business Rules:**
- snapshot_hash cannot be modified (audit immutability)
- evidence_ids captured at package creation time
- status = ACCEPTED means audit passed this package

---

### Support Entities

#### Supplier
**Purpose:** SAP MM supplier simulation

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| sap_id | VARCHAR(20) | | SAP supplier code |
| name | VARCHAR(255) | NOT NULL | Supplier name |
| country | VARCHAR(2) | | Country code |
| rating | DECIMAL(3,1) | DEFAULT 0.0 | Quality rating (0-10) |
| certifications | JSON | | Array of cert codes |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Business Rules:**
- rating 0-10 scale (0=untested, 10=excellent)
- rating impacts supplier_risk KPI

---

#### Material
**Purpose:** SAP MM material simulation

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| sap_id | VARCHAR(20) | | SAP material code |
| name | VARCHAR(255) | NOT NULL | Material name |
| category | VARCHAR(50) | | Product category |
| supplier_id | UUID | FK → Supplier | Who supplies |
| lifespan_months | INT | | Expected lifespan |
| created_at | TIMESTAMP | NOT NULL | Record creation |

---

### Analytics

#### KPISnapshot
**Purpose:** Time-series data for KPI dashboard

| Column | Type | Constraint | Description |
|--------|------|-----------|-------------|
| id | UUID | PK | Unique identifier |
| asset_health_index | DECIMAL(5,2) | | % (0-100) |
| compliance_score | DECIMAL(5,2) | | % (0-100) |
| audit_readiness | DECIMAL(5,2) | | % (0-100) |
| maintenance_efficiency | DECIMAL(5,2) | | % (0-100) |
| supplier_risk_score | DECIMAL(5,2) | | % (0-100) |
| timestamp | TIMESTAMP | NOT NULL | When measured |
| created_at | TIMESTAMP | NOT NULL | Record creation |

**Calculation Logic:**
```
asset_health_index = 
  (Assets with no failed inspections) / Total Assets × 100

compliance_score = 
  (Controls with evidence) / Total required controls × 100

audit_readiness = 
  (Evidence complete and current) / Required evidence × 100

maintenance_efficiency = 
  (Planned maintenance) / Total maintenance orders × 100

supplier_risk_score = 
  (High-rated suppliers) / Total suppliers × 100
```

---

## 🔄 Relationships Summary

| From | To | Type | Cardinality | Description |
|------|----|----|-----|---|
| Asset | Inspection | Has Many | 1:∞ | Asset has many inspections |
| Asset | Control | Has Many | 1:∞ | Asset subject to multiple controls |
| Asset | AuditEvidence | Has Many | 1:∞ | Asset has supporting evidence |
| ComplianceRule | Control | Has Many | 1:∞ | Rule defines multiple controls |
| Control | NonConformance | Has Many | 1:∞ | Control can have violations |
| NonConformance | CorrectiveAction | Has Many | 1:∞ | NC can have multiple actions |
| AuditEvidence | EvidenceLink | Has Many | 1:∞ | Evidence links to controls |
| EvidenceLink | Control | Belongs To | ∞:1 | Link references control |
| Supplier | Material | Has Many | 1:∞ | Supplier provides materials |
| Asset | Supplier | Belongs To | ∞:1 | Asset sourced from supplier |

---

## 📊 Query Patterns (Common Reads)

### Get Asset Health
```sql
SELECT asset_id, 
       COUNT(*) as total_inspections,
       SUM(CASE WHEN result='PASS' THEN 1 ELSE 0 END) as passed
FROM inspection
WHERE asset_id = ?
GROUP BY asset_id;
```

### Get Compliance Status for Control
```sql
SELECT c.id, c.name, c.status,
       COUNT(el.id) as evidence_count
FROM control c
LEFT JOIN audit_evidence ae ON ae.asset_id = c.asset_id
LEFT JOIN evidence_link el ON el.evidence_id = ae.id
WHERE c.id = ?
GROUP BY c.id;
```

### Get Due Inspections
```sql
SELECT * FROM asset
WHERE next_inspection_due <= CURRENT_DATE
AND status = 'ACTIVE'
ORDER BY next_inspection_due ASC;
```

### Get Open Non-Conformances
```sql
SELECT nc.*, c.name as control_name
FROM non_conformance nc
JOIN control c ON c.id = nc.control_id
WHERE nc.status IN ('OPEN', 'IN_PROGRESS')
ORDER BY nc.severity DESC, nc.identified_date ASC;
```

---

## 🗄️ Indexing Strategy

**High-Priority Indexes:**
- `asset(status)` - Frequent filtering by status
- `inspection(asset_id, inspection_date)` - Most common query pattern
- `control(rule_id, status)` - Compliance status queries
- `non_conformance(status, severity)` - Priority filtering
- `audit_evidence(asset_id, created_at)` - Evidence retrieval
- `kpi_snapshot(timestamp DESC)` - Latest KPI queries

---

## 💾 Data Retention Policy

| Entity | Retention | Archive Rule |
|--------|-----------|---|
| Inspection | 7 years | After 7 years → Archive |
| Non-Conformance | 5 years | After resolution + 3 years → Archive |
| Corrective Action | 5 years | After completion + 3 years → Archive |
| Audit Evidence | 7 years (FINAL), 6 months (DRAFT) | Based on regulatory requirement |
| KPI Snapshot | 24 months | Rollup to monthly, then archive |

---

**Document Version:** 1.0  
**Last Updated:** June 2026  
**Next Review:** September 2026