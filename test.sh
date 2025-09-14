#!/bin/bash

echo "=== 专注于 Query 服务测试 (端口 8380) ==="

# proto文件路径
PROTO_PATH="Signal-Server/service/src/main/proto"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}这是为 Signal Server 设计的主要查询接口${NC}"
echo ""

# 1. Distinguished 方法测试
echo -e "${YELLOW}1. 测试 Distinguished Key 查询 (无参数)${NC}"
echo "   这是客户端的第一次KT请求，获取初始树头"
echo ""

grpcurl -plaintext \
  -proto "$PROTO_PATH/KeyTransparencyService.proto" \
  -import-path "$PROTO_PATH" \
  -d '{}' \
  localhost:8380 \
  kt_query.KeyTransparencyQueryService/Distinguished

echo ""
echo "---"
echo ""

# 2. Distinguished 方法测试（带参数）
echo -e "${YELLOW}2. 测试 Distinguished Key 查询 (带last参数)${NC}"
echo "   模拟后续请求，用于一致性验证"
echo ""

grpcurl -plaintext \
  -proto "$PROTO_PATH/KeyTransparencyService.proto" \
  -import-path "$PROTO_PATH" \
  -d '{"last": 1}' \
  localhost:8380 \
  kt_query.KeyTransparencyQueryService/Distinguished

echo ""
echo "---"
echo ""

# 3. HTTP端点对比
echo -e "${YELLOW}3. HTTP 端点状态对比${NC}"
echo ""

echo -n "健康检查: "
curl -s -w "%{http_code}\n" -o /dev/null http://localhost:8384/health 2>/dev/null

echo -n "指标收集: "
curl -s -w "%{http_code}\n" -o /dev/null http://localhost:8383/metrics 2>/dev/null

echo ""
echo -e "${BLUE}=== 解读结果 ===${NC}"
echo ""
echo -e "${GREEN}成功响应示例:${NC}"
echo '{"tree_head": {"tree_size": "1", "timestamp": "...", "signatures": [...]}}'
echo ""
echo -e "${YELLOW}可能的错误类型:${NC}"
echo "• Connection refused = KT Server 未启动"
echo "• Unauthenticated = 需要认证（但Query服务通常不需要）"
echo "• ValidationException = 参数格式错误（正常，说明服务在运行）"
echo "• Internal error = DynamoDB连接或配置问题"
echo ""
echo -e "${BLUE}注意: Audit 服务 (端口8382) 主要供第三方审计员使用，${NC}"
echo -e "${BLUE}可能需要特殊认证或使用不同的接口定义。${NC}"
