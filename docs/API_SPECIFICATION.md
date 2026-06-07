# EnergyTrace360 REST API Specification

## Base URL
```
http://localhost:3001/api  (Development)
https://energytrace360.example.com/api  (Production)
```

---

## 📋 Common Response Formats

### Success Response (2xx)
```json
{
  "success": true,
  "data": { /* entity or array */ },
  "timestamp": "2026-06-07T14:35:00Z"
}
```

### Error Response (4xx, 5xx)
```json
{
  "success": false,
  "error": "Description of error",
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2026-06-07T14:35:00Z"
}
```

### Pagination (List Endpoints)
```json
{
  "success": true,
  "data": [ /* items */ ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  },
  "timestamp": "2026-06-07T14:35:00Z"
}
```

---

## 🔐 Authentication

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "username": "john.doe@example.com",
  "password": "secure-password"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 86400,
    "user": {
      "id": "user-123",
      "username": "john.doe@example.com",
      "role": "MANAGER",
      "name": "John Doe"
    }
  }
}
```

### Get Profile
```http
GET /auth/profile
Authorization: Bearer {token}
```

### Logout
```http
POST /auth/logout
Authorization: Bearer {token}
```

---

## 📊 Asset Service Endpoints

### List Assets
```http
GET /assets?page=1&per_page=20&status=ACTIVE&sort=name:asc
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` (int, default: 1)
- `per_page` (int, default: 20)
- `status` (enum: ACTIVE, MAINTENANCE, INACTIVE)
- `sort` (string: `field:asc|desc`)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "asset-001",
      "name": "Centrifugal Pump A1",
      "type": "Pump",
      "status": "ACTIVE",
      "location": "Building 3, Floor 2",
      "inspection_frequency_days": 30,
      "last_inspection_date": "2026-06-01T10:30:00Z",
      "last_inspection_result": "PASS",
      "next_inspection_due": "2026-07-01T10:30:00Z",
      "created_at": "2026-01-15T08:00:00Z",
      "updated_at": "2026-06-01T10:30:00Z",
      "created_by": "admin"
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 267, "total_pages": 14 }
}
```

### Get Asset Detail
```http
GET /assets/{id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "asset-001",
    "name": "Centrifugal Pump A1",
    "type": "Pump",
    "status": "ACTIVE",
    "location": "Building 3, Floor 2",
    "inspection_frequency_days": 30,
    "last_inspection_date": "2026-06-01T10:30:00Z",
    "last_inspection_result": "PASS",
    "next_inspection_due": "2026-07-01T10:30:00Z",
    "created_at": "2026-01-15T08:00:00Z",
    "updated_at": "2026-06-01T10:30:00Z",
    "created_by": "admin",
    "inspections": [
      {
        "id": "insp-001",
        "inspection_date": "2026-06-01T10:30:00Z",
        "result": "PASS",
        "inspector_id": "inspector-01",
        "notes": "Normal operation",
        "anomaly_detected": false
      }
    ],
    "health_index": 87.5
  }
}
```

### Create Asset
```http
POST /assets
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Centrifugal Pump A1",
  "type": "Pump",
  "location": "Building 3, Floor 2",
  "inspection_frequency_days": 30
}
```

**Response:** (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "asset-001",
    "name": "Centrifugal Pump A1",
    "type": "Pump",
    "status": "ACTIVE",
    "location": "Building 3, Floor 2",
    "inspection_frequency_days": 30,
    "created_at": "2026-06-07T14:35:00Z"
  }
}
```

### Update Asset
```http
PUT /assets/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "MAINTENANCE",
  "location": "Building 3, Floor 3"
}
```

### Get Asset Inspections
```http
GET /assets/{id}/inspections?page=1&per_page=10
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "insp-001",
      "asset_id": "asset-001",
      "inspection_date": "2026-06-01T10:30:00Z",
      "result": "PASS",
      "inspector_id": "inspector-01",
      "notes": "Normal operation",
      "anomaly_detected": false,
      "created_at": "2026-06-01T10:30:00Z"
    }
  ],
  "pagination": { "page": 1, "per_page": 10, "total": 45, "total_pages": 5 }
}
```

### Record Inspection
```http
POST /assets/{id}/inspections
Authorization: Bearer {token}
Content-Type: application/json

{
  "inspection_date": "2026-06-07T14:00:00Z",
  "result": "PASS",
  "inspector_id": "inspector-01",
  "notes": "Pump operating normally",
  "anomaly_detected": false
}
```

**Response:** (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "insp-100",
    "asset_id": "asset-001",
    "inspection_date": "2026-06-07T14:00:00Z",
    "result": "PASS",
    "inspector_id": "inspector-01",
    "notes": "Pump operating normally",
    "anomaly_detected": false,
    "created_at": "2026-06-07T14:00:00Z"
  }
}
```

---

## ⚙️ Compliance Service Endpoints

### List Compliance Rules
```http
GET /rules?page=1&per_page=20&standard=ISO14001
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "rule-001",
      "name": "Environmental Management System",
      "standard": "ISO14001",
      "version": "2015",
      "description": "Requirements for environmental compliance",
      "effective_date": "2026-01-01",
      "created_at": "2026-01-15T08:00:00Z"
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 8, "total_pages": 1 }
}
```

### Get Rule with Controls
```http
GET /rules/{id}/controls
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "rule": {
      "id": "rule-001",
      "name": "Environmental Management System",
      "standard": "ISO14001",
      "version": "2015"
    },
    "controls": [
      {
        "id": "ctrl-001",
        "name": "Environmental Policy",
        "description": "Organization has documented environmental policy",
        "status": "MET",
        "evidence_required": true,
        "assigned_to": "manager-01",
        "due_date": "2026-12-31"
      }
    ]
  }
}
```

### Create Control
```http
POST /rules/{id}/controls
Authorization: Bearer {token}
Content-Type: application/json

{
  "asset_id": "asset-001",
  "name": "Environmental Monitoring",
  "description": "Monthly environmental impact assessment",
  "evidence_required": true,
  "status": "PENDING",
  "assigned_to": "manager-02",
  "due_date": "2026-12-31"
}
```

### Update Control Status
```http
PUT /controls/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "MET",
  "reviewed_date": "2026-06-07T14:00:00Z"
}
```

### Report Non-Conformance
```http
POST /controls/{id}/non-conformances
Authorization: Bearer {token}
Content-Type: application/json

{
  "description": "Environmental waste disposal not documented",
  "severity": "HIGH",
  "identified_date": "2026-06-06T10:00:00Z",
  "root_cause": "Lack of procedure documentation"
}
```

**Response:** (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "nc-001",
    "control_id": "ctrl-001",
    "description": "Environmental waste disposal not documented",
    "severity": "HIGH",
    "identified_date": "2026-06-06T10:00:00Z",
    "root_cause": "Lack of procedure documentation",
    "status": "OPEN",
    "created_at": "2026-06-07T14:00:00Z"
  }
}
```

### List Non-Conformances
```http
GET /non-conformances?status=OPEN&severity=CRITICAL&page=1
Authorization: Bearer {token}
```

### Create Corrective Action
```http
POST /non-conformances/{id}/corrective-actions
Authorization: Bearer {token}
Content-Type: application/json

{
  "action_description": "Create waste disposal procedure and train staff",
  "assigned_to": "manager-03",
  "due_date": "2026-07-07"
}
```

---

## 📄 Evidence Service Endpoints

### Upload Evidence
```http
POST /evidence
Authorization: Bearer {token}
Content-Type: multipart/form-data

asset_id: asset-001
type: DOCUMENT
file: [binary file data]
file_name: Environmental_Policy_2026.pdf
status: FINAL
```

**Response:** (201 Created)
```json
{
  "success": true,
  "data": {
    "id": "evid-001",
    "asset_id": "asset-001",
    "type": "DOCUMENT",
    "file_url": "https://storage.example.com/evid-001.pdf",
    "file_name": "Environmental_Policy_2026.pdf",
    "file_size": 2048576,
    "version": 1,
    "status": "FINAL",
    "created_by": "user-123",
    "created_at": "2026-06-07T14:00:00Z"
  }
}
```

### Link Evidence to Control
```http
POST /evidence/{id}/link/{controlId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "link_type": "SUPPORTS"
}
```

**Valid link_type:** SUPPORTS, CONTRADICTS, CLARIFIES

### Get Asset Evidence
```http
GET /assets/{id}/evidence
Authorization: Bearer {token}
```

### Retrieve Evidence Detail
```http
GET /evidence/{id}
Authorization: Bearer {token}
```

### List All Evidence
```http
GET /evidence?status=FINAL&type=DOCUMENT&page=1
Authorization: Bearer {token}
```

---

## 📈 KPI Endpoints

### Get All KPIs
```http
GET /kpi/all
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "asset_health_index": 87.50,
    "compliance_score": 93.20,
    "audit_readiness": 78.90,
    "maintenance_efficiency": 72.10,
    "supplier_risk_score": 88.40,
    "po_open_count": 5,
    "invoice_completion_rate": 91.50,
    "timestamp": "2026-06-07T14:35:00Z"
  }
}
```

### Get Asset Health KPI
```http
GET /kpi/asset-health
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "value": 87.50,
    "total_assets": 267,
    "passed": 232,
    "failed": 35,
    "timestamp": "2026-06-07T14:35:00Z"
  }
}
```

### Get Compliance Score KPI
```http
GET /kpi/compliance-score
Authorization: Bearer {token}
```

### Get Audit Readiness KPI
```http
GET /kpi/audit-readiness
Authorization: Bearer {token}
```

### Get Maintenance Efficiency KPI
```http
GET /kpi/maintenance-efficiency
Authorization: Bearer {token}
```

### Get Historical KPIs
```http
GET /kpi/history?days=7
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "asset_health_index": 85.20,
      "compliance_score": 92.50,
      "audit_readiness": 76.80,
      "maintenance_efficiency": 70.50,
      "supplier_risk_score": 87.20,
      "timestamp": "2026-06-01T14:00:00Z"
    },
    {
      "asset_health_index": 87.50,
      "compliance_score": 93.20,
      "audit_readiness": 78.90,
      "maintenance_efficiency": 72.10,
      "supplier_risk_score": 88.40,
      "timestamp": "2026-06-07T14:00:00Z"
    }
  ]
}
```

---

## 🏭 SAP MM Mock Adapter Endpoints

### Get Suppliers
```http
GET /sap/mm/suppliers?$filter=rating ge 8&$orderby=name asc&$top=20
Authorization: Bearer {token}
```

**Response (OData format):**
```json
{
  "d": {
    "results": [
      {
        "id": "supplier-001",
        "sap_id": "0000010001",
        "name": "Premium Components Ltd",
        "country": "DE",
        "rating": 9.2,
        "certifications": ["ISO9001", "ISO14001"]
      }
    ]
  }
}
```

### Get Materials
```http
GET /sap/mm/materials?$filter=category eq 'Pump Parts'
Authorization: Bearer {token}
```

### Get Purchase Orders
```http
GET /sap/mm/purchase-orders?$filter=status eq 'OPEN'
Authorization: Bearer {token}
```

### Create Purchase Order
```http
POST /sap/mm/purchase-orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "supplier_id": "supplier-001",
  "material_id": "material-001",
  "quantity": 100,
  "unit_price": 45.50,
  "delivery_date": "2026-07-15"
}
```

---

## 🛒 SAP SD Mock Adapter Endpoints

### Get Customers
```http
GET /sap/sd/customers?$top=50
Authorization: Bearer {token}
```

**Response:**
```json
{
  "d": {
    "results": [
      {
        "id": "customer-001",
        "sap_id": "0000100001",
        "name": "Industrial Solutions GmbH",
        "country": "AT",
        "credit_limit": 500000.00
      }
    ]
  }
}
```

### Get Sales Orders
```http
GET /sap/sd/orders?$filter=status eq 'OPEN'
Authorization: Bearer {token}
```

### Create Sales Order
```http
POST /sap/sd/orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "customer_id": "customer-001",
  "order_date": "2026-06-07",
  "items": [
    {
      "material_id": "material-001",
      "quantity": 50,
      "unit_price": 125.00
    }
  ]
}
```

### Get Invoices
```http
GET /sap/sd/invoices?$filter=status eq 'OPEN'
Authorization: Bearer {token}
```

---

## ❌ Error Codes

| Code | HTTP | Meaning |
|------|------|---------|
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | User lacks permission |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `DUPLICATE_ENTRY` | 409 | Resource already exists |
| `INTERNAL_ERROR` | 500 | Server error |

**Error Response Example:**
```json
{
  "success": false,
  "error": "User lacks permission to update control",
  "errorCode": "FORBIDDEN",
  "timestamp": "2026-06-07T14:35:00Z"
}
```

---

## 🔄 Rate Limiting

- **Standard:** 100 requests/minute per user
- **Burst:** 500 requests/minute
- **Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

---

## 📝 Versioning

- Current API version: **v1** (implicit)
- Future: Support `/api/v2/` for backward compatibility

---

## 🧪 Testing

See `TESTING.md` for Postman collection and integration test instructions.

