# EnergyTrace360 System Architecture

## 📐 Overall Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FRONTEND LAYER (React)                             │
│                    Dashboard | Assets | Compliance | Evidence               │
└─────────────────────────┬───────────────────────────┬───────────────────────┘
                          │ REST API                  │ REST API
                          │ (Polling 30s interval)    │
         ┌────────────────┴───────────────────────────┴─────────┐
         │                                                      │
         ▼                                                      ▼
    ┌─────────────────────────────────────────────────────────────────────┐
    │                   BACKEND SERVICES LAYER (Node.js)                  │
    │                                                                     │
    │  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
    │  │  Asset Service   │  │ Compliance Svc   │  │ Evidence Svc   │  │
    │  │                  │  │                  │  │                │  │
    │  │ • Asset CRUD     │  │ • Rules Mgmt     │  │ • Document    │  │
    │  │ • Inspection Log │  │ • Control Track  │  │   Storage      │  │
    │  │ • Health Calc    │  │ • NonConformance │  │ • Link Ctrl    │  │
    │  │ • KPI Compute    │  │ • KPI Compute    │  │ • Evidence Mgmt│  │
    │  └──────────────────┘  └──────────────────┘  └────────────────┘  │
    │         ▲                      ▲                      ▲            │
    │         │                      │                      │            │
    │  ┌──────┴──────────────────────┴──────────────────────┴─────────┐ │
    │  │              KPI CALCULATION ENGINE (Shared)              │ │
    │  │  • Asset Health Index                                     │ │
    │  │  • Compliance Score                                       │ │
    │  │  • Audit Readiness                                        │ │
    │  │  • Maintenance Efficiency                                 │ │
    │  │  • Supplier Risk Score                                    │ │
    │  │  • Invoice Completion Rate                                │ │
    │  │  • PO Fulfillment Rate                                    │ │
    │  └───────────────────────────────────────────────────────────┘ │
    │                                                                     │
    │  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
    │  │ SAP MM Adapter   │  │ SAP SD Adapter   │  │  Auth Service  │  │
    │  │ (Mock OData)     │  │ (Mock OData)     │  │  (JWT/RBAC)    │  │
    │  │                  │  │                  │  │                │  │
    │  │ GET /suppliers   │  │ GET /customers   │  │ POST /login    │  │
    │  │ GET /materials   │  │ GET /orders      │  │ GET /profile   │  │
    │  │ GET /po          │  │ GET /invoices    │  │                │  │
    │  │ POST /po         │  │ POST /orders     │  │                │  │
    │  └──────────────────┘  └──────────────────┘  └────────────────┘  │
    └──────────────────────────────────────────────────────────────────┘
                          ▲                 ▲
                          │                 │
         ┌────────────────┴────────────────┴────────────┐
         │                                             │
         ▼                                             ▼
    ┌──────────────────────────────┐    ┌──────────────────────────────┐
    │     PostgreSQL Database      │    │   File Storage (Mock)        │
    │                              │    │                              │
    │  • Assets                    │    │   Evidence & Documents       │
    │  • Inspections               │    │   (Base64 in DB for demo)    │
    │  • Compliance Rules          │    │                              │
    │  • Controls                  │    │   Optional: S3-like mock     │
    │  • NonConformances           │    │                              │
    │  • CorrectiveActions         │    │                              │
    │  • AuditEvidence             │    │                              │
    │  • KPI Snapshots             │    │                              │
    │  • Suppliers, Materials, PO  │    │                              │
    │  • Audit Log                 │    │                              │
    └──────────────────────────────┘    └──────────────────────────────┘
```

---

## 🎯 Core Domains (Domain-Driven Design)

### 1. Asset Integrity Domain
**Entities:**
- `Asset` - Equipment/machinery record
- `Inspection` - Inspection event record
- Aggregate: `AssetWithHistory` (Asset + latest inspection + health calc)

**Business Rules:**
- Asset status transitions: ACTIVE → MAINTENANCE → ACTIVE (or INACTIVE)
- Inspection frequency is configurable per asset
- Next inspection due calculated from frequency
- Health index: (Passed Inspections / Total Inspections) × 100

**API Endpoints:**
```
GET    /api/assets                         (list all)
GET    /api/assets/:id                     (detail)
POST   /api/assets                         (create)
PUT    /api/assets/:id                     (update)
GET    /api/assets/:id/inspections         (history)
POST   /api/assets/:id/inspections         (record new)
GET    /api/kpi/asset-health               (KPI calculation)
```

---

### 2. Compliance Management Domain
**Entities:**
- `ComplianceRule` - ISO 14001, ISO 9001, etc.
- `Control` - Specific control requirement
- `NonConformance` - Control violation
- `CorrectiveAction` - Fix/remediation
- Aggregate: `ControlWithEvidence` (Control + linked evidence)

**Business Rules:**
- Controls inherit from rules (parent-child relationship)
- Control status: MET, NOT_MET, PENDING
- NonConformance severity: CRITICAL, HIGH, MEDIUM, LOW
- Corrective actions must be approved before closing
- Evidence must support control status

**API Endpoints:**
```
GET    /api/rules                          (list standards)
GET    /api/rules/:id/controls             (controls in rule)
POST   /api/rules/:id/controls             (create control)
GET    /api/controls/:id                   (detail)
PUT    /api/controls/:id                   (update status)
POST   /api/controls/:id/non-conformances  (report violation)
GET    /api/non-conformances               (list)
PUT    /api/non-conformances/:id           (update)
POST   /api/corrective-actions             (create action)
GET    /api/kpi/compliance-score           (KPI calculation)
GET    /api/kpi/audit-readiness            (KPI calculation)
```

---

### 3. Evidence & Audit Domain
**Entities:**
- `AuditEvidence` - Document/file linked to assets/controls
- `EvidenceLink` - Junction table (Evidence ↔ Control)
- `AuditLog` - Change history (who, what, when)

**Business Rules:**
- Evidence versioning (track updates)
- Evidence can be: DRAFT, FINAL, ARCHIVED
- Evidence expires (retention policy)
- All changes to core entities logged in AuditLog
- Many-to-many: Evidence ↔ Controls

**API Endpoints:**
```
POST   /api/evidence                       (upload/create)
GET    /api/evidence/:id                   (retrieve)
PUT    /api/evidence/:id                   (update version)
DELETE /api/evidence/:id                   (soft delete to ARCHIVED)
POST   /api/evidence/:id/link/:controlId   (link to control)
GET    /api/assets/:id/evidence            (evidence by asset)
GET    /api/audit-log                      (change history)
```

---

### 4. SAP MM Integration Domain (Mock)
**Entities:**
- `Supplier` - SAP Vendor master
- `Material` - SAP Material master
- `PurchaseOrder` - SAP PO document

**OData Mock Endpoints (SAP-style):**
```
GET    /sap/mm/suppliers                   (with $filter, $orderby)
GET    /sap/mm/suppliers/:id
GET    /sap/mm/materials
GET    /sap/mm/materials/:id
GET    /sap/mm/purchase-orders
GET    /sap/mm/purchase-orders/:id
POST   /sap/mm/purchase-orders             (create PO)
```

**KPI Integration:**
- Supplier Risk Score = average rating of active suppliers
- PO Open Count = count of purchase-orders with status OPEN
- Material Availability = materials in stock / total materials

---

### 5. SAP SD Integration Domain (Mock)
**Entities:**
- `Customer` - SAP Customer master
- `SalesOrder` - SAP Sales Order
- `Invoice` - SAP Invoice/delivery

**OData Mock Endpoints (SAP-style):**
```
GET    /sap/sd/customers
GET    /sap/sd/customers/:id
GET    /sap/sd/orders
GET    /sap/sd/orders/:id
POST   /sap/sd/orders                      (create order)
GET    /sap/sd/invoices
GET    /sap/sd/invoices/:id
```

**KPI Integration:**
- Invoice Completion Rate = invoiced amount / total order amount
- Order Fulfillment Rate = completed orders / total orders

---

## 📊 KPI Definitions & Calculation

| KPI | Domain | Formula | Update | Target |
|-----|--------|---------|--------|--------|
| **Asset Health Index** | Asset Integrity | (Passed Inspections / Total Inspections) × 100 | Polling 30s | >85% |
| **Compliance Score** | Compliance | (MET Controls / Total Controls) × 100 | Polling 1h | >95% |
| **Audit Readiness** | Evidence | (Controls with Evidence / Total Controls) × 100 | Polling 1h | 100% |
| **Maintenance Efficiency** | Asset Integrity | (Planned Maintenance / Total) × 100 | Polling 24h | >70% |
| **Supplier Risk Score** | MM Integration | Average Supplier Rating × 10 | Polling 24h | >85% |
| **PO Open Count** | MM Integration | COUNT(PO where status='OPEN') | Polling 1h | <10 |
| **Invoice Completion** | SD Integration | (Invoiced / Total Orders) × 100 | Polling 24h | >90% |

**Polling Strategy:**
- Real-time KPIs (Asset Health): 30 seconds
- Daily KPIs (Compliance, Audit): 1 hour
- Weekly KPIs (Efficiency, Supplier Risk): 24 hours
- Frontend: User can manually refresh

---

## 🏗️ Service Communication Patterns

### Synchronous (REST)
Used for:
- Queries (list, detail)
- User-initiated actions (create, update)
- KPI calculations (on-demand)
- SAP adapter calls (stateless)

### Database (Direct)
Used for:
- State persistence
- ACID transactions
- Historical data (KPI snapshots)
- Audit logging

### No Event Bus
**By Design:**
- Kafka NOT used (per constraints)
- Simple REST polling sufficient for portfolio demo
- Each service maintains own state
- KPI calculations are idempotent and re-runnable

---

## 🔐 Security Model

### Authentication
- JWT tokens (Bearer scheme)
- Login endpoint: `POST /api/auth/login`
- Token includes: userId, role, expires_at

### Authorization (RBAC)
```
Roles:
  • VIEWER: Read-only access to dashboard
  • AUDITOR: Read + view evidence, audit logs
  • MANAGER: Read + create/update compliance, KPIs
  • ADMIN: All permissions + user management
```

### Data Protection
- Sensitive data (SSN, etc): Encrypted at rest (noted in docs)
- HTTPS enforced in production
- API rate limiting (noted in docs)
- CORS configured for frontend origin only

---

## 📦 Deployment Model

### Docker Compose (Development)
```
Services:
  • postgres:14 (database)
  • backend (Node.js Express)
  • frontend (React dev server)
  • sap-adapter (Mock SAP OData)
```

### Production (Conceptual)
- Container orchestration: Kubernetes or SAP BTP
- Database: Managed PostgreSQL (AWS RDS, Azure, SAP BTP HANA)
- Frontend: CDN + static hosting
- Backend: Container registry + auto-scaling
- Environment variables for configuration

---

## 🔄 Data Flow Example: Recording an Inspection

```
1. Frontend: User opens Asset detail page
   └─> GET /api/assets/{id}

2. Frontend: Shows "Record Inspection" form

3. User: Fills form (result: PASS, notes, etc)

4. Frontend: Submits
   └─> POST /api/assets/{id}/inspections { result, notes, ... }

5. Backend (Asset Service):
   a) Insert inspection record in DB
   b) Calculate new Asset Health Index
   c) Update asset.last_inspection_date
   d) Calculate next_inspection_due
   e) Log change in audit_log table
   f) Return inspection record + health

6. Frontend: 
   a) Show success toast
   b) Refresh asset detail
   c) Dashboard KPI will pick up change on next poll (30s)

7. Dashboard (Polling):
   └─> GET /api/kpi/asset-health  (every 30s)
   └─> Updates chart with new data point
```

---

## 📈 Scalability Considerations

### Current Design Limits
- Single backend instance (add horizontal scaling for production)
- PostgreSQL single-instance (replicate for HA)
- Polling interval creates query load (tuned per KPI)

### Future Optimizations (Not in MVP)
- Database query optimization (indexing done)
- Caching layer (Redis)
- Read replicas for analytics
- Batch processing for historical KPI snapshots
- Possible: Event bus if real-time <500ms needed

---

## ✅ Clean Architecture Principles

✅ **Separation of Concerns**
- Each service owns its domain entities
- Adapters isolated for SAP integration
- Clear request/response contracts

✅ **Testability**
- Services accept database/config via constructor
- Mock implementations for adapters
- No static dependencies

✅ **Maintainability**
- Code organized by domain (Asset, Compliance, Evidence)
- Configuration externalized to environment
- Audit log for change tracking

✅ **Scalability**
- Database indexes on hot queries
- Stateless services (horizontally scalable)
- KPI snapshots for historical analysis

