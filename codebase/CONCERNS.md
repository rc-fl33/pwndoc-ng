# PwnDoc-NG Technical Concerns and Risks

## Operational Concerns

### 1. Data Persistence & Backup
| Concern | Details | Mitigation |
|---|---|---|
| No backup mechanism | MongoDB data stored in Docker named volume with no automated backup | Implement EBS snapshots (AWS) or mongodump cron job to S3 |
| Report templates on filesystem | Templates mounted from host via Docker volume. Loss of host = loss of templates | Store in S3 with versioning. Back up regularly |
| Images in MongoDB | Images stored as base64 in MongoDB documents. Large images bloat the database | Consider S3 for image storage. Set upload size limits |
| Single MongoDB instance | No replication or failover configured | For production: use MongoDB Atlas replica set or run a replica set on EC2 |

### 2. Scalability Limitations
| Concern | Details | Mitigation |
|---|---|---|
| Monolithic backend | Single Node.js process handles API, Socket.IO, and Hocuspocus | Acceptable for small teams (<20 users). For larger: separate WebSocket server |
| In-memory Socket.IO | Socket.IO stores room/user state in-memory. Cannot scale horizontally | Add Redis adapter for Socket.IO if running multiple backend instances |
| Hocuspocus in-process | Collaborative editing server runs in same process as API | Separate into its own service for better resource isolation |
| Large report generation | Report generation is CPU/memory-intensive (docxtemplater + image processing) | Could block the event loop. Consider worker threads or a separate report generation queue |
| 100MB JSON body limit | `body-parser` allows 100MB JSON payloads, could cause OOM on small instances | Reduce to 10-20MB. Use multipart uploads for large files |

### 3. Reliability Concerns
| Concern | Details | Mitigation |
|---|---|---|
| No health checks | No `/health` or `/ready` endpoints for container orchestration | Add health check endpoints that verify DB connectivity |
| No graceful shutdown | Express server doesn't handle SIGTERM gracefully | Add graceful shutdown handler for in-flight requests |
| Cron job in app process | Auto-deletion cron runs inside the main app. If app restarts, timing resets | Acceptable for daily cron, but consider external scheduler for critical jobs |
| Hardcoded container names | Docker compose uses hardcoded container names and `links` (deprecated) | Use service names for DNS resolution (already works via Docker networking) |

### 4. Development & Maintenance Concerns
| Concern | Details | Mitigation |
|---|---|---|
| Outdated Node.js base image | Backend uses `node:20.0.0-alpine3.16` (pinned to old Alpine) | Update to latest `node:20-alpine` |
| Frontend uses `--openssl-legacy-provider` | Build script requires legacy OpenSSL flag, indicating outdated crypto dependencies | Update webpack/quasar to remove this requirement |
| Unused Electron dependencies | Frontend `package.json` includes electron but doesn't use it | Remove unused dependencies to reduce bundle size and attack surface |
| No TypeScript | Entire codebase is JavaScript without type checking | Consider gradual TypeScript migration for new code |
| Promise anti-patterns | Many models wrap Mongoose promises in `new Promise()` unnecessarily | Refactor to use async/await directly |
| Deprecated Docker Compose v2 | `docker-compose.yml` uses `version: '3'` format and `links` | Update to modern Compose spec |
| No `.env` file pattern | Config hardcoded in `config.json` rather than environment variables | Refactor to use `dotenv` or environment variable precedence |

## Application-Level Concerns

### 5. Report Generation Risks
| Concern | Details | Mitigation |
|---|---|---|
| Global mutable state | Report generator uses module-level globals (`numberOfPieChart`, `globalAbstractNumId`, etc.) | Risk of race conditions if two reports generate simultaneously. Add request-level scoping |
| Template injection | Angular expressions in docxtemplater could potentially be abused if user-controlled data contains expression syntax | Sanitize user input before template rendering |
| File path traversal | Template path constructed from user-controllable `audit.template.name` | Validate template name doesn't contain path traversal characters |
| Memory spikes | Large audits with many images processed entirely in-memory | Consider streaming approach or worker processes for large reports |

### 6. Data Integrity Concerns
| Concern | Details | Mitigation |
|---|---|---|
| No DB schema migrations | Schema changes rely on Mongoose defaults and manual field removal in settings.js | Implement a migration system for schema evolution |
| Findings embedded in audit | Findings are subdocuments, not separate collections. MongoDB 16MB document limit applies | Very large audits (100+ findings with images) could hit the limit |
| Soft delete only for users | Users can't be deleted, only disabled, to preserve audit references | Document this clearly. Consider anonymization for GDPR compliance |
| No optimistic concurrency | Multiple users editing the same audit could cause last-write-wins conflicts (outside of collab-edited fields) | Hocuspocus handles rich text fields; other fields still vulnerable |
| Vulnerability copy (not reference) | When adding a finding from vulnerability DB, data is copied, not linked | Changes to vulnerability DB don't propagate to existing findings (by design, but can cause inconsistency) |

### 7. Auto-Deletion Risk
| Concern | Details | Mitigation |
|---|---|---|
| Dangerous automation feature | Settings allow auto-deleting audits older than N days | This is behind a `danger.enabled` flag but should have additional safeguards |
| No soft-delete for audits | `deleteOutdatedReportAutomation` permanently removes audit data | Add soft-delete or archive to S3 before permanent deletion |
| No deletion audit trail | No log of what was deleted and when | Log all auto-deletions with audit details |

## Monitoring Requirements for AWS

### Essential Metrics to Track
1. **Application**: Response times, error rates, active WebSocket connections
2. **MongoDB**: Connection count, query performance, disk usage, replication lag
3. **ECS/EC2**: CPU utilization, memory usage, container restarts
4. **Network**: ALB request count, 4xx/5xx error rates, latency percentiles
5. **Security**: Failed login attempts, unauthorized access attempts

### Recommended Alarms
| Alarm | Threshold | Action |
|---|---|---|
| CPU utilization | > 80% for 5 min | Scale up or investigate |
| Memory utilization | > 85% | Scale up (report generation is memory-intensive) |
| MongoDB disk usage | > 80% | Expand EBS volume |
| 5xx error rate | > 5% of requests | Investigate immediately |
| Container restarts | > 3 in 10 min | Investigate OOM or crash loops |
| Failed logins | > 20 in 5 min | Potential brute force, check WAF |
