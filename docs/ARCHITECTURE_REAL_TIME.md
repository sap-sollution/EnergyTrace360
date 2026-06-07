# Real-Time KPI Architecture

## 🔴 Current State: REST Polling (NOT Real-Time)

### Current Implementation
```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND DASHBOARD                      │
│  (React + Chart.js)                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                    REST GET /kpi
                    (every 5-30s)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    KPI SERVICE (REST)                       │
│  ❌ Synchronous query                                       │
│  ❌ Polling latency (5-30s delay)                           │
│  ❌ Database load on each poll                              │
│  ❌ No event awareness                                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   POSTGRESQL DATABASE                       │
│  Compute KPI on demand:                                     │
│  - Asset Health: SELECT COUNT(*) WHERE...                   │
│  - Compliance Score: SELECT AVG(score)...                   │
│  - Audit Readiness: SELECT...                               │
└─────────────────────────────────────────────────────────────┘
```

**Problems:**
- ⏱️ **Latency**: 5-30 second delay between event and dashboard update
- 💻 **Resource Intensive**: Query executed on every poll
- 📊 **Not Scalable**: Every user polling = N×database queries
- 🔄 **No Event Context**: Dashboard unaware of change triggers
- ❌ **Misleading Label**: Line 114 in README says "real-time" but isn't

---

## ✅ Target State: Event-Driven Real-Time

### Architecture Pattern: Event Sourcing + WebSocket Streaming

```
┌──────────────────────────────────────────────────────────────┐
│                   BUSINESS EVENTS                            │
│  (AssetInspectionCompleted, ComplianceControlUpdated, etc)   │
└────────────┬─────────────────────────────────┬───────────────┘
             │                                 │
      ┌──────▼──────┐                   ┌──────▼──────┐
      │ Asset Svc   │                   │ Compliance  │
      │ (Kafka)     │                   │ Svc (Kafka) │
      └──────┬──────┘                   └──────┬──────┘
             │                                 │
             └─────────────┬───────────────────┘
                           │
                    KAFKA MESSAGE BUS
                    (Event Stream)
                           │
                    ┌──────▼──────────┐
                    │  KPI AGGREGATOR │
                    │  (Real-time)    │
                    │                 │
                    │  Listens to:    │
                    │  • Inspections  │
                    │  • Compliance   │
                    │  • Evidence     │
                    │                 │
                    │  Maintains:     │
                    │  • In-memory KPI│
                    │  • Time-series  │
                    │  • State cache  │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐        ┌─────▼─────┐      ┌─────▼─────┐
    │ WebSocket│        │ REST API  │      │ Time-Series│
    │ /events  │        │ /kpi/live │      │ DB (TSDB)  │
    │(SSE)     │        │(Fallback) │      │(InfluxDB)  │
    └────┬────┘        └──────────┬──────┘      └───────────┘
         │                        │
         │              ┌─────────┘
         │              │
    ┌────▼──────────────▼──────────┐
    │  FRONTEND DASHBOARD           │
    │  (Real-time subscription)     │
    │                               │
    │  ✅ <100ms latency            │
    │  ✅ Bi-directional updates    │
    │  ✅ Event-driven              │
    │  ✅ Scalable (push vs pull)   │
    └───────────────────────────────┘
```

---

## 📊 KPI Update Latency Comparison

| Metric | Current (REST) | Target (Real-Time) |
|--------|----------------|-------------------|
| **Latency** | 5-30 seconds | <100 milliseconds |
| **Trigger** | Polling interval | Event fired |
| **Scalability** | O(n) queries | O(1) broadcasts |
| **DB Load** | High (every poll) | Medium (event processing) |
| **User Experience** | "Stale" data | Live updates |
| **Architecture** | Request-Response | Event-Driven |

---

## 🎯 Audit: Which KPIs Need Real-Time?

| KPI | Current Frequency | Actual Need | Implementation |
|-----|------------------|-------------|-----------------|
| **Asset Health Index** | "Real-time" ❌ | ✅ YES (inspection events) | Event-driven, WebSocket |
| **Compliance Score** | Daily | ⚠️ MAYBE (daily refresh enough) | Scheduled batch |
| **Audit Readiness** | Weekly | ❌ NO (can be weekly) | Scheduled batch |
| **Maintenance Efficiency** | Monthly | ❌ NO (can be monthly) | Scheduled batch |
| **Supplier Risk Score** | Monthly | ❌ NO (can be monthly) | Scheduled batch |

**Recommendation:** Only **Asset Health Index** needs true real-time. Others = scheduled updates.

---

## 🚀 Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Add Kafka to Docker Compose
- [ ] Create Kafka producer in Asset Service
- [ ] Emit `AssetInspectionCompleted` event on inspection record
- [ ] Add event schema to `docs/EVENTS.md`

### Phase 2: Real-Time Engine (Week 2-3)
- [ ] Create KPI Aggregator service
- [ ] Subscribe to Kafka topics
- [ ] Maintain in-memory KPI cache
- [ ] Add REST endpoint `/api/kpi/snapshot` (low latency)

### Phase 3: WebSocket Streaming (Week 3-4)
- [ ] Add Socket.IO to Express backend
- [ ] Create WebSocket namespace `/kpi-stream`
- [ ] Push KPI updates on event arrival
- [ ] Client subscribes to real-time events

### Phase 4: Historical Analytics (Week 4-5)
- [ ] Add InfluxDB for time-series
- [ ] Store KPI snapshots every minute
- [ ] Add `/api/kpi/history?range=1h` endpoint
- [ ] Dashboard chart loads historical + live data

### Phase 5: Documentation (Week 5)
- [ ] Update README with architecture diagram
- [ ] Add dashboard screenshots
- [ ] Record demo video (2-3 min)
- [ ] Update KPI definitions table

---

## 💻 Code Examples

### Event Schema (Kafka)

```json
{
  "eventType": "AssetInspectionCompleted",
  "assetId": "ASSET-001",
  "timestamp": "2026-06-07T14:35:00Z",
  "data": {
    "inspectionStatus": "PASS",
    "anomaliesDetected": 0,
    "nextScheduledDate": "2026-07-07"
  }
}
```

### KPI Aggregator (Pseudo-Code)

```javascript
// Listen to Kafka topic
kafkaConsumer.subscribe(['asset-events', 'compliance-events']);

kafkaConsumer.on('message', (message) => {
  const event = JSON.parse(message.value);
  
  switch(event.eventType) {
    case 'AssetInspectionCompleted':
      // Update Asset Health Index in-memory
      kpiCache.assetHealthIndex = recalculateHealth();
      
      // Broadcast to WebSocket clients
      io.to('kpi-subscribers').emit('kpi-update', {
        assetHealthIndex: kpiCache.assetHealthIndex,
        timestamp: new Date()
      });
      
      // Store in time-series DB
      tsdb.write('asset_health', kpiCache.assetHealthIndex);
      break;
  }
});
```

### WebSocket Client (React)

```javascript
import { useEffect, useState } from 'react';
import io from 'socket.io-client';

function KPIDashboard() {
  const [kpis, setKpis] = useState(null);
  
  useEffect(() => {
    const socket = io('/kpi-stream');
    
    socket.on('kpi-update', (data) => {
      setKpis(prev => ({ ...prev, ...data }));
      // Chart updates immediately
    });
    
    return () => socket.disconnect();
  }, []);
  
  return <div>{/* Real-time chart rendering */}</div>;
}
```

---

## 🔍 Success Metrics

✅ After implementation:
- Asset Health Index updates in <100ms from event
- Dashboard shows "Live" indicator when connected
- Zero polling requests to KPI endpoint
- Kafka consumer lag <1 second
- CPU usage reduced (push vs pull)
- Support team stops asking "why is the dashboard stale?"

---

## 📚 References

- [Kafka Event Streaming Architecture](https://kafka.apache.org/documentation/#design)
- [WebSocket Real-Time Patterns](https://socket.io/)
- [Time-Series Databases (InfluxDB)](https://www.influxdata.com/)
- [Event Sourcing Pattern](https://martinfowler.com/eaaDev/EventSourcing.html)
