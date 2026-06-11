# digital-finance-infra — AI 开发代理规范

## 项目身份
- **名称**: 数字金融彩票 - 基础设施
- **类型**: Nginx API 反向代理 + Docker Compose 编排

## 架构

```
服务器端口:
  16000 → Nginx (API 反向代理)
  16010 → Admin 管理后台 (直连)
  16020 → Mobile 移动端 (直连)

Nginx (16000) 反向代理:
  /api/* → go-backend:16080
  /ai/*  → ai-service:16081

Admin/Mobile 通过 NEXT_PUBLIC_API_BASE_URL=http://服务器IP:16000 调用 API
```

## 关键约定
- 服务命名: df- 前缀
- 网络: digital-finance-network (bridge)，**禁止硬编码 IP**
- Nginx 只代理后端 API，不做前端代理
- 日志: json-file driver, max-size: 10m, max-file: 3

## 部署文件

### docker-compose.yml (根目录) — 后端基础服务
postgres + redis + go-backend + ai-service + nginx，全部从 SWR 拉取镜像。

### scripts/ — 前端部署
| 文件 | 服务 | 端口 |
|------|------|------|
| `docker-compose.admin.yml` | 管理后台 | 16010 |
| `docker-compose.mobile.yml` | 移动端前端 | 16020 |

## 部署

### 服务器需要的文件
```
/opt/digital-finance/
├── docker-compose.yml          # 后端基础服务 (5个容器)
└── scripts/
    ├── .env                    # 环境变量 (cp .env.example .env)
    ├── .env.example
    ├── docker-compose.admin.yml
    └── docker-compose.mobile.yml
```

### 部署命令
```bash
# 1. 部署后端基础服务
cd /opt/digital-finance
docker compose up -d

# 2. 部署前端
cd scripts
docker compose -f docker-compose.admin.yml up -d
docker compose -f docker-compose.mobile.yml up -d
```

## SWR 镜像
| 服务 | SWR 路径 |
|------|----------|
| Go 后端 | `.../digital-finance-commercial/go-backend` |
| AI 服务 | `.../digital-finance-commercial/ai-service` |
| Admin | `.../digital-finance-commercial/admin` |
| Mobile | `.../digital-finance-commercial/mobile` |
| Nginx | `.../digital-finance-commercial/nginx` |