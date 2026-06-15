# digital-finance-infra — AI 开发代理规范

## 项目身份
- **名称**: 数字金融彩票 - 基础设施
- **类型**: Nginx API 反向代理 + Docker Compose 编排
- **职责**: 只管理基础设施服务 (postgres / redis / nginx)，**禁止**编排任何应用服务

## 架构

```
服务器端口:
  16000 → Nginx (API 反向代理)
  16010 → Admin 管理后台 (直连)
  16020 → Mobile 移动端 (直连)

Nginx (16000) 反向代理:
  /api/* → go-backend:16080   (由 digital-finance-services 独立部署)
  /ai/*  → ai-service:16081   (由 digital-finance-ai-service 独立部署)

Admin/Mobile 通过 NEXT_PUBLIC_API_BASE_URL=http://服务器IP:16000 调用 API
```

## 关键约定
- 服务命名: df- 前缀
- 网络: digital-finance-network (bridge)，**禁止硬编码 IP**
- **infra compose 中不允许出现应用服务 (go-backend / ai-service / admin / mobile)**
- 应用服务由各自工程的 docker-compose 独立编排，加入同一 network 即可
- Nginx 只代理后端 API，不做前端代理
- 日志: json-file driver, max-size: 10m, max-file: 3

## 部署文件

### deploy/ — 统一部署目录 (服务器端)
所有部署文件集中在根目录 `deploy/`，复制到服务器后运行 `./deploy.sh` 即可一键部署。

| 文件 | 说明 |
|------|------|
| `deploy.sh` | **一键部署脚本** (首次自动创建 .env，后续更新自动拉取最新镜像) |
| `.env.example` | 环境变量模板 (自动复制为 .env) |
| `docker-compose.infra.yml` | 基础服务 (postgres + redis + nginx) |
| `docker-compose.services.yml` | Go 后端 API |
| `docker-compose.ai.yml` | AI 服务 |
| `docker-compose.admin.yml` | 管理后台 (端口 16010) |
| `docker-compose.mobile.yml` | 移动端前端 (端口 16020) |

### scripts/ — 开发机构建脚本
| 文件 | 说明 |
|------|------|
| `swr-build-push.ps1` | Windows PowerShell 构建 & 推送全部镜像到 SWR |
| `swr-build-push.sh` | Linux/macOS 构建 & 推送全部镜像到 SWR |
| `package.sh` | 打包 deploy/ 为 deploy.tar.gz 便于 SCP |

## 部署工作流

### 开发机 → 构建镜像
```bash
# Windows (PowerShell)
.\scripts\swr-build-push.ps1 -Tag v1.0.0

# Linux/macOS
./scripts/swr-build-push.sh v1.0.0
```

### 开发机 → 打包
```bash
./scripts/package.sh v1.0.0    # 生成 deploy.tar.gz
scp deploy.tar.gz root@服务器IP:/opt/
```

### 服务器 → 部署
```bash
ssh root@服务器IP
cd /opt && tar xzf deploy.tar.gz
cd digital-finance-deploy-v1.0.0
./deploy.sh                     # 首次运行提示编辑 .env，修改后重新运行即可
```

## SWR 镜像
| 服务 | SWR 路径 |
|------|----------|
| Go 后端 | `.../digital-finance-commercial/go-backend` |
| AI 服务 | `.../digital-finance-commercial/ai-service` |
| Admin | `.../digital-finance-commercial/admin` |
| Mobile | `.../digital-finance-commercial/mobile` |
| Nginx | `.../digital-finance-commercial/nginx` |
