#!/bin/bash
# =============================================================================
# 数字金融彩票 — 部署参考脚本
# 
# 用途: 指导你手动复制文件到服务器并部署
# 说明: 本脚本仅供开发机参考使用，不提交到 Git
# 
# 服务器工作目录: /opt/digital-finance
# =============================================================================

# ======================== 第一步: 复制文件到服务器 ========================

# 在开发机上执行以下命令，将文件复制到服务器：

SERVER_USER="root"
SERVER_IP="YOUR_SERVER_IP"
SERVER_DIR="/opt/digital-finance"

# --- 复制 scripts/ 目录 (前端部署文件) ---
# scp -r ./* ${SERVER_USER}@${SERVER_IP}:${SERVER_DIR}/scripts/

# --- 复制根 compose 文件 (后端 + Nginx) ---
# scp ../docker-compose.yml ${SERVER_USER}@${SERVER_IP}:${SERVER_DIR}/


# ======================== 第二步: 服务器上操作 ========================

# SSH 登录服务器后执行：

# 1. 创建工作目录
# mkdir -p /opt/digital-finance/scripts
# cd /opt/digital-finance

# 2. 创建环境变量配置
# cp scripts/.env.example scripts/.env
# vim scripts/.env   # 修改以下必填项:
#                    #   POSTGRES_PASSWORD=你的强密码
#                    #   JWT_SECRET=64位以上随机字符串
#                    #   API_KEY=你的AI服务API密钥
#                    #   TAG=latest (或指定版本)

# 3. 登录华为云 SWR (首次部署需要)
# docker login swr.ap-southeast-3.myhuaweicloud.com

# 4. 部署后端基础服务 + Nginx (postgres + redis + go-backend + ai-service + nginx)
# docker compose up -d

# 5. 等待后端就绪，部署前端 (独立端口访问)
# cd scripts
# docker compose -f docker-compose.admin.yml up -d
# docker compose -f docker-compose.mobile.yml up -d

# 6. 检查所有服务状态
# cd /opt/digital-finance
# docker compose -f docker-compose.yml -f scripts/docker-compose.admin.yml -f scripts/docker-compose.mobile.yml ps


# ======================== 服务器文件结构 ========================

# /opt/digital-finance/                  # 工作根目录
# ├── docker-compose.yml                 # 基础服务 (postgres+redis+go-backend+ai-service+nginx)
# └── scripts/                           # 前端部署脚本
#     ├── .env                           # 环境变量 (从 .env.example 复制后修改)
#     ├── .env.example                   # 环境变量模板
#     ├── docker-compose.admin.yml       # 管理后台 (独立端口 16010)
#     └── docker-compose.mobile.yml      # 移动端前端 (独立端口 16020)


# ======================== 架构说明 ========================
#
#   ┌──────────────────────────────────────────────────┐
#   │                    服务器                          │
#   │                                                   │
#   │  外部端口:                                         │
#   │   16000 → Nginx Gateway (API 反向代理)             │
#   │   16010 → Admin 管理后台                           │
#   │   16020 → Mobile 移动端                            │
#   │                                                   │
#   │  Nginx Gateway (16000) 统一路由:                    │
#   │   /api/* → go-backend:16080 (Go 后端 API)          │
#   │   /ai/*  → ai-service:16081 (AI 服务)              │
#   │                                                   │
#   │  Admin/Mobile 服务端 rewrites:                     │
#   │   通过 API_GATEWAY_URL=http://nginx:80             │
#   │   → Next.js 服务端转发到 Nginx Gateway             │
#   │   → Nginx 再转发到对应后端服务                      │
#   │                                                   │
#   │  内部网络: digital-finance-network (bridge)         │
#   └──────────────────────────────────────────────────┘
#
# 请求链路:
#   浏览器 → http://服务器IP:16010 或 16020
#          → Next.js rewrites (服务端)
#          → Nginx Gateway (nginx:80)
#          → go-backend:16080 或 ai-service:16081
#   浏览器始终使用相对路径 /api/ 和 /ai/ 即可


# ======================== 更新部署 ========================

# 更新镜像并重启:
# TAG=v1.2.3 docker compose up -d --force-recreate
# cd scripts && TAG=v1.2.3 docker compose -f docker-compose.admin.yml up -d --force-recreate
# cd scripts && TAG=v1.2.3 docker compose -f docker-compose.mobile.yml up -d --force-recreate

# 或修改 .env 中的 TAG 值，然后:
# docker compose pull
# docker compose up -d