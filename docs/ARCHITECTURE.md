# EnergyTrace360 - Architecture Overview

## 🧭 Architecture Principles

- **Domain-Driven Design (DDD)** - Clear domain boundaries and ubiquitous language
- **Layered Architecture** - Separation of concerns (UI, Application, Domain, Data)
- **API-First Design** - All services expose REST APIs
- **Adapter Pattern** - SAP integration via adapter (not tight coupling)
- **Event-Driven Concepts** - Notification of domain events (for future async processing)

---

## 🏗️ System Layers

```
┌─────────────────────────────────────────────────────┐
│                  Frontend Layer (React)             │
│         KPI Dashboard + Asset Management UI         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┼──────────────────────────────┐
│           Application Layer (REST APIs)             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│
│  │Asset Service │ │Compliance Svc│ │ Evidence Svc ││
│  └──────────────┘ └──────────────┘ └──────────────┘│
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┼──────────────────────────────┐
│      Integration Layer (SAP Adapter + Events)      │
│      SAP MM Mock Adapter | Event Simulation        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────┼──────────────────────────────┐
│         Data Layer (PostgreSQL + Storage)          │
│    Domain Entities | Audit Trail | Versioning     │
└─────────────────────────────────────────────────────┘
```

---

## 🧱 Core Domains (DDD)

### Domain 1: Asset Integrity

**Entities:**
- Asset (root aggregate)
- Inspection
- MaintenanceOrder

**Responsibilities:**
- Asset registry and lifecycle management
- Inspection scheduling and recording
- Anomaly detection (rule-based: deviation from normal inspection patterns)
- Maintenance request generation

**Key Business Rules:**
- Assets must have periodic inspections (frequency by asset type)
- Failed inspections trigger automatic compliance alerts
- Maintenance orders link back to SAP MM (simulated)

**Example Flow:**
```
1. Scheduler creates inspection due for Asset X
2. Inspector records PASS/FAIL
3. If FAIL → System flags compliance issue
4. Generates maintenance order suggestion
5. Updates asset health KPI
```

---

### Domain 2: Compliance Management

**Entities:**
- ComplianceRule (root aggregate)
- Control
- NonConformance
- CorrectiveAction

**Responsibilities:**
- Define compliance framework (ISO 14001 aligned)
- Map controls to assets and processes
- Track non-conformances
- Manage corrective action workflows

**Key Business Rules:**
- Each control has required evidence
- Non-conformance must have corrective action
- Corrective actions require approval (workflow simulation)
- Controls must be reviewed regularly (audit trail)

**Example Flow:**
```
1. Define ISO 14001 control: "All hazardous materials tracked"
2. Map to Assets (storage tanks, chemical containers)
3. For each asset: generate compliance checklist
4. If evidence missing → Non-conformance
5. Create corrective action → Approval → Close
6. Track in audit readiness
```

---

### Domain 3: Audit Evidence

**Entities:**
- Evidence (root aggregate)
- EvidenceLink
- AuditPackage

**Responsibilities:**
- Centralized evidence repository
- Linking evidence to controls and assets
- Version control and audit trail
- Evidence pack generation for auditors

**Key Business Rules:**
- Evidence must be linked to at least one control
- All changes tracked with timestamp and user
- Evidence can be: documents, inspection results, photos, test reports
- Audit packages immutable (snapshot at audit date)

**Example Flow:**
```
1. Inspector uploads inspection report (evidence)
2. System auto-links to Asset X and related Controls
3. Compliance engine: Evidence Count +1
4. Audit Readiness %: increases
5. Auditor requests evidence pack
6. System generates immutable snapshot (timestamp + seal)
```

---

## 🔌 Integration Layer Architecture

### SAP MM Adapter (Mock)

**Purpose:** Simulate OData API patterns for SAP MM without real S/4HANA connection

**Endpoints:**
```
GET /sap/mm/suppliers           → Mock supplier master data
GET /sap/mm/materials           → Mock material master data
GET /sap/mm/assets              → Mock asset master data
POST /sap/mm/asset-link         → Link asset to material/supplier
GET /sap/mm/asset-link/{id}     → Get asset linkage details
```

**Mock Data Structure:**
```json
{
  "supplier": {
    "id": "SUPP-001",
    "name": "GreenEnergy Ltd",
    "country": "DE",
    "rating": 9.2,
    "certifications": ["ISO 14001", "ISO 45001"]
  },
  "material": {
    "id": "MAT-12345",
    "name": "Industrial Turbine Blade",
    "category": "Equipment",
    "supplier_id": "SUPP-001",
    "lifespan_months": 24
  }
}
```

**Design Decision:** No real OData connection - adapter returns mock data with realistic structure
- ✅ Allows demonstration of integration patterns
- ✅ No SAP system dependency
- ✅ Realistic for portfolio showcase

### Event Simulation Layer

**Purpose:** Demonstrate event-driven architecture concepts

**Mock Events:**
```
AssetInspectionCompleted     → Triggers compliance check
NonConformanceLogged         → Triggers corrective action workflow
CorrectiveActionApproved     → Updates compliance score
AuditPackageRequested        → Generates evidence snapshot
```

**Future Enhancement:** Real async event processing via BTP Event Mesh

---

## 📊 Analytics Layer

### KPI Calculation Engine

**KPI 1: Asset Health Index**
```
Formula: (Assets with no failed inspections) / Total Assets × 100
Source: Asset Integrity Domain
Frequency: Real-time (recalc on each inspection)
Example: 85 healthy assets / 100 total = 85%
```

**KPI 2: Compliance Score**
```
Formula: (Controls with evidence) / Total controls required × 100
Source: Compliance Management Domain
Frequency: Daily
Example: 95 controls with evidence / 100 required = 95%
```

**KPI 3: Audit Readiness**
```
Formula: (Evidence complete + current) / Required evidence × 100
Source: Evidence Domain
Frequency: Weekly
Example: All compliance controls have evidence = 100%
```

**KPI 4: Maintenance Efficiency**
```
Formula: (Planned maintenance orders) / Total maintenance orders × 100
Source: Asset Integrity Domain
Frequency: Monthly
Example: 70 planned / 100 total = 70%
```

**KPI 5: Supplier Risk Score**
```
Formula: (Green-rated suppliers) / Total suppliers × 100
Source: SAP MM Adapter simulation
Frequency: Monthly
Example: 9 high-rated / 10 total = 90%
```

---

## 🔄 Data Flow Examples

### Flow 1: Inspection Triggers Compliance Check

```
┌─────────────────────────────────────────────────────────┐
│ 1. Inspector Posts Inspection Result                    │
│    POST /api/assets/{assetId}/inspections              │
│    { result: "FAIL", notes: "Pressure reading high" }  │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Asset Service Updates Asset Status                   │
│    asset.lastInspectionStatus = "FAIL"                 │
│    asset.lastInspectionDate = now                       │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ 3. Compliance Service Triggered (via adapter)           │
│    Finds controls linked to this asset                  │
│    Evaluates rules: IF lastInspection=FAIL             │
│    THEN update compliance_score                         │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ 4. Evidence Service Records Event                       │
│    Creates audit trail entry                            │
│    Links to both Asset and Compliance Control           │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│ 5. Dashboard KPIs Recalculated (real-time)             │
│    Asset Health Index: -1%                             │
│    Compliance Score: -2%                                │
│    UI updates automatically                             │
└─────────────────────────────────────────────────────────┘
```

### Flow 2: Non-Conformance Creates Corrective Action

```
Compliance Control Not Met
        ↓
Evidence Missing / Outdated
        ↓
System Logs Non-Conformance
        ↓
Create Corrective Action (workflow)
        ↓
Route to Manager for Approval (simulated)
        ↓
Close Corrective Action
        ↓
Compliance Score Updated
        ↓
Audit Readiness Improves
```

---

## 🛡️ Security & RBAC

**Roles:**
- **Admin** - Full system access, manage users, system configuration
- **Manager** - Approve corrective actions, view all audit evidence
- **Inspector** - Record inspections, upload evidence
- **Auditor** - Read-only access to audit evidence and reports
- **Viewer** - Read-only dashboard access

**Authentication:** JWT tokens (mock)  
**Authorization:** Role-based access control (RBAC)

---

## 📦 Deployment Architecture

### Development (Docker Compose)
```
┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
│   Frontend  │  │  Backend     │  │  PostgreSQL     │
│  (React)    │  │  (Node.js)   │  │  (DB)           │
└─────────────┘  └──────────────┘  └─────────────────┘
        └──────────────┬──────────────┘
           Docker Network (development)
```

### Production (Cloud-Ready)
```
┌──────────────────────────────────────────┐
│        SAP BTP Cloud Foundry             │
│  ┌──────────────────────────────────┐   │
│  │  Frontend (React SPA)            │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  Backend Services (Node/Java)    │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  SAP HANA / PostgreSQL           │   │
│  └──────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

---

## 🧪 Testing Strategy

- **Unit Tests** - Domain logic (compliance rules, KPI calculations)
- **Integration Tests** - Service-to-service communication
- **API Tests** - REST endpoint contracts
- **Mock Data Tests** - SAP adapter responses

---

## 📈 Scalability Considerations

- **Horizontal Scaling** - Stateless services can scale
- **Database** - PostgreSQL with indexes on frequently queried fields
- **Caching** - KPI snapshots cached (real-time refresh every 5 minutes)
- **Archive Strategy** - Old evidence archived after audit completion

---

## 🚀 Migration Path (If Connecting Real SAP)

1. Replace mock SAP adapter with real OData connector (SAP Cloud SDK)
2. Add SAP authentication (OAuth2 / SAML)
3. Real BTP workflow engine integration
4. Event Mesh for async processing
5. Connector to SAP Analytics Cloud (for ESG metrics)

---

## ⚠️ Architectural Constraints

- No direct S/4HANA database access (only APIs)
- No complex ML algorithms (rule-based only)
- No external ESG calculation engines
- No blockchain or distributed ledger
- Compliance engine is pattern demonstrator (not regulatory tool)

---

## 🔄 Future Architecture Evolution

### Phase 2 (Post-MVP)
- ESG metrics aggregation layer
- Digital Product Passport data structure
- Advanced analytics (trend analysis)

### Phase 3 (Long-term)
- Multi-tenant SaaS deployment
- Real BTP event processing
- ML-based anomaly detection
- Integration with SAP Analytics Cloud

---

**Document Version:** 1.0  
**Last Updated:** June 2026  
**Next Review:** September 2026