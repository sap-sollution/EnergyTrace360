# EnergyTrace360 - Quick Start Guide

## Prerequisites

- Docker & Docker Compose (v20.10+)
- Git
- Text editor (VS Code recommended)

## Installation & Launch

### 1. Clone Repository
```bash
git clone https://github.com/sap-sollution/EnergyTrace360.git
cd EnergyTrace360
```

### 2. Start All Services
```bash
docker-compose up -d
```

This command starts:
- **PostgreSQL** (port 5432) - Database with 7 core entities
- **Backend** (port 3001) - REST API services
- **SAP Adapter** (port 3002) - Mock SAP MM OData endpoints
- **Frontend** (port 3000) - React KPI dashboard

### 3. Wait for Services to Be Ready
```bash
# Check service health
curl http://localhost:3001/health
curl http://localhost:3002/health
```

### 4. Access the Application

- **Dashboard:** http://localhost:3000
- **Backend API:** http://localhost:3001/api
- **SAP Adapter:** http://localhost:3002/sap
- **Database:** localhost:5432 (credentials in docker-compose.yml)

---

## API Endpoints (Reference)

### Asset Service
```
GET    /api/assets                 - List assets
GET    /api/assets/:id             - Get asset details
POST   /api/assets                 - Create asset
PUT    /api/assets/:id             - Update asset
POST   /api/assets/:id/inspections - Record inspection
GET    /api/assets/:id/inspections - Get inspection history
```

### Compliance Service
```
GET    /api/compliance/status                      - Get compliance overview
GET    /api/compliance/assets/:assetId/controls   - Get asset controls
POST   /api/compliance/non-conformances           - Log non-conformance
```

### Evidence Service
```
GET    /api/evidence/assets/:assetId              - Get asset evidence
POST   /api/evidence/upload                       - Upload evidence
```

### Analytics Service
```
GET    /api/analytics/kpis                        - Get current KPIs
GET    /api/analytics/kpis/history?days=30       - Get KPI history
```

### SAP Mock Adapter
```
GET    /sap/mm/suppliers                          - List suppliers
GET    /sap/mm/materials                          - List materials
POST   /sap/mm/asset-link                         - Link asset to material
GET    /sap/mm/supplier-risk                      - Get supplier risk score
```

---

## Database Schema

### 7 Core Entities

1. **Asset** - Equipment and infrastructure items
2. **Inspection** - Inspection records and results
3. **ComplianceRule** - ISO 14001 and other standards
4. **Control** - Individual compliance controls
5. **NonConformance** - Compliance violations
6. **AuditEvidence** - Documents and evidence files
7. **KPISnapshot** - Time-series KPI data

### Support Tables
- **Supplier** - SAP MM supplier simulation
- **Material** - SAP MM material simulation
- **EvidenceLink** - Many-to-many evidence-to-control mapping
- **CorrectiveAction** - Actions to fix non-conformances
- **AuditLog** - Change tracking

---

## Development Workflow

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Stop Services
```bash
docker-compose down
```

### Clean Database
```bash
docker-compose down -v
```

### Access Database
```bash
docker exec -it energytrace360-db psql -U energytrace -d energytrace360

# List tables
\dt

# Query example
SELECT * FROM asset;
```

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│  React Frontend (Port 3000)             │
│  KPI Dashboard & Asset Management       │
└─────────────────────────────────────────┘
              ↓                   ↓
┌──────────────────────┐  ┌──────────────────────┐
│  Node.js Backend     │  │  SAP Mock Adapter    │
│  (Port 3001)         │  │  (Port 3002)         │
│  • Asset Service     │  │  • Suppliers         │
│  • Compliance Svc    │  │  • Materials         │
│  • Evidence Svc      │  │  • Risk Scoring      │
│  • Analytics Svc     │  └──────────────────────┘
└──────────────────────┘
              ↓
┌──────────────────────────────────────┐
│  PostgreSQL Database (Port 5432)     │
│  7 Core Entities + Support Tables    │
└──────────────────────────────────────┘
```

---

## Support & Troubleshooting

### Port Conflicts
If ports are already in use, modify docker-compose.yml:
```yaml
ports:
  - "8000:3000"  # Use port 8000 instead
```

### Database Connection Issues
```bash
# Check database is running
docker ps | grep postgres

# Reset database
docker-compose down -v
docker-compose up -d postgres
```

### Frontend Not Loading
```bash
# Check frontend logs
docker-compose logs frontend

# Rebuild frontend
docker-compose build --no-cache frontend
docker-compose up frontend
```

---

## Next Steps

1. Explore the dashboard at http://localhost:3000
2. Query APIs directly: `curl http://localhost:3001/api/assets`
3. Review data model in `database/schema.sql`
4. Examine business logic in `backend/server.js`
5. Customize for your use case

---

**Last Updated:** June 2026  
**Status:** ✅ Ready for Deployment
