# AWS Deployment Architecture - Cost-Optimized

## Deployment Options (Cheapest to Most Production-Ready)

---

## Option 1: Single EC2 Instance (Lowest Cost - Dev/Small Team)

**Estimated Monthly Cost: ~$15-30/month**

```
                    ┌──────────────────────────────────┐
                    │          AWS Cloud (VPC)          │
                    │                                  │
                    │  ┌────────────────────────────┐  │
  Internet ────────►│  │   EC2 t3.small (2GB RAM)   │  │
  (HTTPS:443)       │  │                            │  │
                    │  │  ┌──────────────────────┐  │  │
                    │  │  │  Docker Compose       │  │  │
                    │  │  │  ┌────────────────┐  │  │  │
                    │  │  │  │ Nginx+Frontend  │  │  │  │
                    │  │  │  │ Backend         │  │  │  │
                    │  │  │  │ MongoDB         │  │  │  │
                    │  │  │  │ LanguageTool*   │  │  │  │
                    │  │  │  └────────────────┘  │  │  │
                    │  │  └──────────────────────┘  │  │
                    │  │                            │  │
                    │  │  EBS gp3 20GB              │  │
                    │  └────────────────────────────┘  │
                    │                                  │
                    │  Security Group:                 │
                    │   - 443 inbound (HTTPS)          │
                    │   - 22 inbound (SSH, your IP)    │
                    └──────────────────────────────────┘

* LanguageTool optional - saves ~1GB RAM if disabled
```

### Cost Breakdown
| Resource | Spec | Monthly Cost |
|---|---|---|
| EC2 t3.small | 2 vCPU, 2GB RAM | ~$15 (on-demand), ~$9 (1yr reserved) |
| EBS gp3 | 20GB | ~$1.60 |
| Data transfer | 10GB/month out | ~$0.90 |
| **Total** | | **~$17-18/month** |

### Notes
- Use `t3.medium` (4GB RAM) if running LanguageTool (~$30/month)
- Use Elastic IP ($3.65/month if instance is stopped)
- Consider Spot instances for dev environments (~70% savings)
- No HA or redundancy - acceptable for small teams
- Use Let's Encrypt (free) for SSL via certbot

### Setup Steps
```bash
# 1. Launch EC2 with Amazon Linux 2023 / Ubuntu 22.04
# 2. Install Docker + Docker Compose
# 3. Clone repo, configure environment
# 4. Run docker-compose up -d
# 5. Configure Security Group for port 443
# 6. (Optional) Set up Let's Encrypt with certbot
```

---

## Option 2: ECS Fargate (Serverless Containers - Medium Team)

**Estimated Monthly Cost: ~$50-80/month**

```
                    ┌─────────────────────────────────────────────────┐
                    │                AWS Cloud (VPC)                   │
                    │                                                 │
  Internet ────────►│  ┌─────────────────────┐                        │
  (HTTPS:443)       │  │    ALB (HTTPS)       │   ACM Certificate     │
                    │  │    + WAF (optional)   │   (Free SSL)          │
                    │  └──┬──────┬──────┬─────┘                       │
                    │     │      │      │                              │
                    │  ┌──▼──┐┌──▼──┐┌──▼──────────┐                  │
                    │  │Front││Back ││LanguageTool  │ ECS Fargate      │
                    │  │end  ││end  ││ (optional)   │ (Private Subnet) │
                    │  │256MB││512MB││ 1024MB       │                  │
                    │  │0.25 ││0.25 ││ 0.5 vCPU     │                  │
                    │  │vCPU ││vCPU ││              │                  │
                    │  └─────┘└──┬──┘└──────────────┘                  │
                    │            │                                      │
                    │  ┌─────────▼────────────┐                        │
                    │  │  DocumentDB (or       │  Private Subnet       │
                    │  │  MongoDB on EC2)      │                       │
                    │  └──────────────────────┘                        │
                    └─────────────────────────────────────────────────┘
```

### Cost Breakdown
| Resource | Spec | Monthly Cost |
|---|---|---|
| ALB | Always-on | ~$16 + LCU charges |
| ECS Fargate (Frontend) | 0.25 vCPU, 256MB | ~$4 |
| ECS Fargate (Backend) | 0.25 vCPU, 512MB | ~$7 |
| ECS Fargate (LanguageTool) | 0.5 vCPU, 1024MB | ~$14 (skip to save) |
| MongoDB on EC2 t3.micro | 1 vCPU, 1GB | ~$8 |
| EBS for MongoDB | 20GB gp3 | ~$1.60 |
| ECR | Image storage | ~$1 |
| Data transfer | 10GB/month | ~$0.90 |
| **Total (with LT)** | | **~$53/month** |
| **Total (without LT)** | | **~$38/month** |

### Tradeoffs
- **Pro**: No server management, auto-scaling possible, proper SSL via ACM
- **Pro**: Service isolation, easy deployments via task definitions
- **Con**: More complex setup, DocumentDB is expensive ($200+/mo), use EC2 MongoDB instead
- **Con**: ALB has a minimum fixed cost even with no traffic

### Important: Avoid DocumentDB
DocumentDB is MongoDB-compatible but starts at ~$200/month. Instead:
- Run MongoDB on a dedicated `t3.micro` EC2 instance ($8/month)
- Or use MongoDB Atlas free tier (512MB) for dev, M10 ($57/month) for production

---

## Option 3: ECS with Full Production Setup (Team/Enterprise)

**Estimated Monthly Cost: ~$150-250/month**

```
                    ┌──────────────────────────────────────────────────────┐
                    │                    AWS Cloud (VPC)                    │
                    │                                                      │
                    │  ┌──────────┐    ┌──────────────┐                    │
  Internet ────────►│  │CloudFront│───►│ S3 (Frontend)│  Public Subnet     │
  (HTTPS:443)       │  │  (CDN)   │    │ Static Host  │                    │
                    │  └──────┬───┘    └──────────────┘                    │
                    │         │                                             │
                    │  ┌──────▼──────────────┐                             │
                    │  │    ALB (HTTPS)       │  ACM + WAF                  │
                    │  └──┬──────────────┬───┘                             │
                    │     │              │                                   │
                    │  ┌──▼──────────┐┌──▼──────────┐  Private Subnet      │
                    │  │  Backend    ││LanguageTool  │  ECS Fargate         │
                    │  │  (x2 tasks) ││ (optional)   │  Auto-scaling        │
                    │  └──────┬──────┘└──────────────┘                     │
                    │         │                                             │
                    │  ┌──────▼──────────┐  ┌────────────┐                 │
                    │  │ MongoDB Atlas    │  │ Secrets    │                 │
                    │  │ or EC2 + EBS    │  │ Manager    │                 │
                    │  └─────────────────┘  └────────────┘                 │
                    │                                                      │
                    │  ┌──────────────┐  ┌────────────────┐                │
                    │  │ CloudWatch   │  │ S3 (Templates  │                │
                    │  │ (Logging)    │  │  + Images)     │                │
                    │  └──────────────┘  └────────────────┘                │
                    └──────────────────────────────────────────────────────┘
```

### Cost Breakdown
| Resource | Spec | Monthly Cost |
|---|---|---|
| CloudFront | CDN for frontend | ~$1-5 |
| S3 (frontend static) | Static hosting | ~$0.50 |
| ALB | Load balancer | ~$20 |
| WAF | Basic OWASP rules | ~$10 |
| ECS Fargate (Backend x2) | 0.5 vCPU, 1GB each | ~$28 |
| ECS Fargate (LanguageTool) | 0.5 vCPU, 1.5GB | ~$20 |
| MongoDB Atlas M10 | 2GB RAM, 10GB storage | ~$57 |
| Secrets Manager | 3-5 secrets | ~$2 |
| S3 (templates/images) | 5GB | ~$0.50 |
| CloudWatch Logs | 5GB ingestion | ~$3 |
| Data transfer | 20GB/month | ~$2 |
| **Total** | | **~$145-165/month** |

---

## Recommendation by Use Case

| Use Case | Recommended Option | Est. Cost |
|---|---|---|
| Personal / Learning | Option 1 (EC2 t3.small) | $17/month |
| Small pentest team (2-5 users) | Option 1 (EC2 t3.medium) | $30/month |
| Growing team (5-15 users) | Option 2 (ECS + EC2 MongoDB) | $50-80/month |
| Enterprise / Client-facing | Option 3 (Full production) | $150-250/month |

## Cost Optimization Tips

1. **Skip LanguageTool** unless grammar checking is essential - saves $14-20/month and ~1.5GB RAM
2. **Use Reserved Instances** for always-on EC2 workloads (30-40% savings)
3. **Use Spot Fargate** for non-critical tasks (up to 70% savings, interruption risk)
4. **S3 + CloudFront** for frontend is cheaper than running Nginx in a container
5. **MongoDB Atlas free tier** (512MB) works for dev/testing
6. **Use `t3.small`** (2GB) if you skip LanguageTool; `t3.medium` (4GB) if you keep it
7. **Elastic IP**: Release when not in use ($3.65/month if unattached)
8. **EBS gp3**: Cheaper than gp2 with better baseline performance
9. **Turn off dev environments** on nights/weekends using Lambda + EventBridge schedules
10. **AWS Free Tier**: New accounts get 12 months of t3.micro, 30GB EBS, 5GB S3 free

## Environment Variables for AWS Deployment

```bash
# Required environment variables (move from config.json)
MONGO_URI=mongodb://user:pass@hostname:27017/pwndoc?authSource=admin
JWT_SECRET=<from-secrets-manager>
JWT_REFRESH_SECRET=<from-secrets-manager>
NODE_ENV=prod
COLLAB_WEBSOCKET_PORT=8440

# Optional
LANGUAGETOOL_URL=http://languagetool:8010
LOG_LEVEL=info
```

## Deployment Checklist

- [ ] Choose deployment option based on team size and budget
- [ ] Set up VPC with public/private subnets
- [ ] Configure Security Groups (restrict MongoDB to backend only)
- [ ] Set up ACM certificate for your domain
- [ ] Move secrets to AWS Secrets Manager or SSM Parameter Store
- [ ] Modify `config.json` to read from environment variables
- [ ] Build and push Docker images to ECR
- [ ] Configure ALB with HTTPS listener (Options 2-3)
- [ ] Set up CloudWatch log groups
- [ ] Configure DNS (Route 53 or external)
- [ ] Enable EBS encryption for MongoDB data volume
- [ ] Set up automated backups (EBS snapshots or MongoDB dumps to S3)
- [ ] Test LanguageTool connectivity (or remove if not needed)
- [ ] Verify WebSocket connectivity through ALB (sticky sessions may be needed)
- [ ] Configure ALB target group health checks
