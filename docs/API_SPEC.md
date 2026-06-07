# EnergyTrace360 - REST API Specification

**Base URL:** `http://localhost:3001/api` (Development)

---

## 🔐 Authentication

All endpoints require JWT token in Authorization header:

```
Authorization: Bearer <jwt_token>
```

### Authenticate
```http
POST /auth/login
Content-Type: application/json

{
  "username": "inspector1",
  "password": "password123"
}

Response 200:
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 86400,
  "user": {
    "id": "USER-001",
    "name": "John Inspector",
    "role": "INSPECTOR"
  }
}
```

---

## 📋 Asset Service API

### List All Assets
```http
GET /assets?status=ACTIVE&limit=50&offset=0

Response 200:
{
  "total": 150,
  "limit": 50,
  "offset": 0,
  "data": [
    {
      "id": "ASSET-001",
      "name": "Turbine Unit 1",
      "type": "EQUIPMENT",
      "status": "ACTIVE",
      "location": "Plant A",
      "supplier_id": "SUPP-001",
      "last_inspection_date": "2026-06-05T10:30:00Z",
      "last_inspection_result": "PASS",
      "next_inspection_due": "2026-07-05T10:30:00Z",
      "inspection_frequency_days": 30
    }
  ]
}
```

### Get Asset Details
```http
GET /assets/{assetId}

Response 200:
{
  "id": "ASSET-001",
  "name": "Turbine Unit 1",
  "type": "EQUIPMENT",
  "status": "ACTIVE",
  "location": "Plant A",
  "supplier_id": "SUPP-001",
  "last_inspection_date": "2026-06-05T10:30:00Z",
  "last_inspection_result": "PASS",
  "next_inspection_due": "2026-07-05T10:30:00Z",
  "inspection_frequency_days": 30,
  "created_at": "2026-01-15T08:00:00Z",
  "updated_at": "2026-06-05T10:30:00Z",
  "created_by": "admin"
}
```

### Create Asset
```http
POST /assets
Content-Type: application/json

{
  "name": "Compressor Unit 2",
  "type": "EQUIPMENT",
  "location": "Plant B",
  "supplier_id": "SUPP-002",
  "inspection_frequency_days": 45
}

Response 201:
{
  "id": "ASSET-152",
  "name": "Compressor Unit 2",
  "type": "EQUIPMENT",
  "status": "ACTIVE",
  "location": "Plant B",
  "supplier_id": "SUPP-002",
  "inspection_frequency_days": 45,
  "created_at": "2026-06-07T14:22:30Z"
}
```

### Record Inspection
```http
POST /assets/{assetId}/inspections
Content-Type: application/json

{
  "inspection_date": "2026-06-07T14:00:00Z",
  "result": "PASS",
  "inspector_id": "INS-001",
  "notes": "Equipment running normally. Vibration within limits."
}

Response 201:
{
  "id": "INSP-5421",
  "asset_id": "ASSET-001",
  "inspection_date": "2026-06-07T14:00:00Z",
  "result": "PASS",
  "inspector_id": "INS-001",
  "notes": "Equipment running normally. Vibration within limits.",
  "anomaly_detected": false,
  "created_at": "2026-06-07T14:00:30Z"
}
```

---

## 🔒 Compliance Service API

### Get Compliance Status
```http
GET /compliance/status

Response 200:
{
  "total_controls": 150,
  "met_controls": 143,
  "compliance_percentage": 95.3,
  "non_conformances": [
    {
      "id": "NC-0045",
      "control_id": "CTRL-012",
      "control_name": "Waste disposal documentation",
      "severity": "HIGH",
      "identified_date": "2026-06-01T08:00:00Z",
      "status": "OPEN"
    }
  ]
}
```

### Create Non-Conformance
```http
POST /compliance/non-conformances
Content-Type: application/json

{
  "control_id": "CTRL-012",
  "description": "Missing documentation for waste disposal event on 2026-05-28",
  "severity": "HIGH",
  "root_cause": "Document not filed properly"
}

Response 201:
{
  "id": "NC-0046",
  "control_id": "CTRL-012",
  "description": "Missing documentation...",
  "severity": "HIGH",
  "identified_date": "2026-06-07T14:30:00Z",
  "status": "OPEN",
  "created_at": "2026-06-07T14:30:30Z"
}
```

---

## 📦 Audit Evidence Service API

### Upload Evidence
```http
POST /evidence/upload
Content-Type: multipart/form-data

asset_id: ASSET-001
type: INSPECTION
file: [binary file content]
description: "Inspection report for turbine unit 1"

Response 201:
{
  "id": "EV-0234",
  "asset_id": "ASSET-001",
  "type": "INSPECTION",
  "file_url": "s3://bucket/evidence/EV-0234/report.pdf",
  "file_name": "inspection_report_20260607.pdf",
  "file_size": 2048576,
  "version": 1,
  "status": "FINAL",
  "created_by": "inspector1",
  "created_at": "2026-06-07T14:35:00Z"
}
```

### Get Evidence for Asset
```http
GET /evidence/assets/{assetId}?limit=10

Response 200:
{
  "total": 45,
  "limit": 10,
  "data": [
    {
      "id": "EV-0234",
      "asset_id": "ASSET-001",
      "type": "INSPECTION",
      "file_url": "s3://bucket/evidence/EV-0234/report.pdf",
      "file_name": "inspection_report_20260607.pdf",
      "version": 1,
      "status": "FINAL",
      "created_by": "inspector1",
      "created_at": "2026-06-07T14:35:00Z"
    }
  ]
}
```

---

## 📊 Analytics / KPI API

### Get Current KPIs
```http
GET /analytics/kpis

Response 200:
{
  "timestamp": "2026-06-07T14:50:00Z",
  "asset_health_index": 87.5,
  "compliance_score": 93.2,
  "audit_readiness": 96.8,
  "maintenance_efficiency": 71.4,
  "supplier_risk_score": 88.5,
  "trend": {
    "asset_health_index": "UP",
    "compliance_score": "STABLE",
    "audit_readiness": "UP",
    "maintenance_efficiency": "DOWN",
    "supplier_risk_score": "STABLE"
  }
}
```

### Get KPI History
```http
GET /analytics/kpis/history?days=30

Response 200:
{
  "snapshots": [
    {
      "timestamp": "2026-06-07T14:50:00Z",
      "asset_health_index": 87.5,
      "compliance_score": 93.2,
      "audit_readiness": 96.8,
      "maintenance_efficiency": 71.4,
      "supplier_risk_score": 88.5
    }
  ]
}
```

---

## 🔌 SAP MM Mock Adapter API

### List Suppliers (SAP MM)
```http
GET /sap/mm/suppliers

Response 200:
{
  "suppliers": [
    {
      "id": "SUPP-001",
      "sap_id": "1000001",
      "name": "GreenEnergy Ltd",
      "country": "DE",
      "rating": 9.2,
      "certifications": ["ISO 14001", "ISO 45001", "ISO 9001"]
    }
  ]
}
```

### List Materials (SAP MM)
```http
GET /sap/mm/materials?supplier_id=SUPP-001

Response 200:
{
  "materials": [
    {
      "id": "MAT-001",
      "sap_id": "300000123",
      "name": "Industrial Turbine Blade",
      "category": "EQUIPMENT",
      "supplier_id": "SUPP-001",
      "lifespan_months": 24
    }
  ]
}
```

---

## ❌ Error Responses

### 400 - Bad Request
```json
{
  "error": "BAD_REQUEST",
  "message": "Invalid input format",
  "details": {
    "field": "inspection_date",
    "error": "Date must be in ISO 8601 format"
  }
}
```

### 401 - Unauthorized
```json
{
  "error": "UNAUTHORIZED",
  "message": "Missing or invalid authentication token"
}
```

### 403 - Forbidden
```json
{
  "error": "FORBIDDEN",
  "message": "User does not have permission to access this resource"
}
```

### 404 - Not Found
```json
{
  "error": "NOT_FOUND",
  "message": "Asset not found",
  "resource": "ASSET-999"
}
```

### 500 - Internal Server Error
```json
{
  "error": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "request_id": "req-12345-abcde"
}
```

---

## 📝 Rate Limiting

- **Rate Limit:** 100 requests per minute per user
- **Header:** `X-RateLimit-Remaining: 95`
- **Retry After:** `Retry-After: 60` (seconds)

---

## 🔄 Pagination

All list endpoints support:
- `limit` (default: 20, max: 100)
- `offset` (default: 0)
- `sort` (default: created_at DESC)

Example:
```
GET /assets?limit=50&offset=100&sort=name ASC
```

---

**API Version:** 1.0  
**Last Updated:** June 2026  
**Next Review:** September 2026