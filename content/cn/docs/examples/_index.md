---
title: 示例
description: 通过实际的 CRD 配置了解项目如何运行。
weight: 4
---

{{% pageinfo %}}
本节提供了 OpenResty Operator 中各个核心 CRD 的使用示例。  
每个小节都包含一个代表性的 YAML 配置及其说明。
{{% /pageinfo %}}

## OpenResty 示例

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: OpenResty
metadata:
  name: demo-app
  namespace: openresty-example
spec:
  replicas: 2
  ## image: openresty/openresty:alpine
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "100m"
      memory: "128Mi"
  http:
    include:
      - mime.types
    logFormat: |
      main '$remote_addr - $remote_user [$time_local] "$request" '
      '$status $body_bytes_sent "$http_referer" "$http_user_agent"'
    accessLog: /var/log/nginx/access.log
    errorLog: /var/log/nginx/error.log
    clientMaxBodySize: 2m
    gzip: true
    extra:
      - keepalive_timeout 65;
    serverRefs:
      - demo-server
    upstreamRefs:
      - demo-upstream
  metrics:
    enable: true
    listen: "9090"
    path: /metrics
  serviceMonitor:
    enable: true
    labels:
      release: prometheus
    annotations:
      monitoring: enabled
  reloadAgentEnv:
    - name: RELOAD_POLICY
      value: '{"window":60,"maxEvents":20}'
  logVolume:
    type: EmptyDir
```

## ServerBlock 示例

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: ServerBlock
metadata:
  name: demo-server
  namespace: openresty-example
spec:
  listen: "80"
  accessLog: "/var/log/nginx/access.log main"
  errorLog: "/var/log/nginx/error.log warn"
  headers:
    - key: X-Frame-Options
      value: DENY
    - key: X-Content-Type-Options
      value: nosniff
  locationRefs:
    - demo-location
```

> ℹ️ 每个 `ServerBlock` 都会对应一个 Kubernetes Service，其 DNS 名称为 `<name>.<namespace>.svc.cluster.local`，该名称将作为 Nginx 的 `server_name` 使用。


## Location 示例

`Location` CR 定义了每个 Nginx `location` 区块的路由规则，通常绑定到具体的路径。每条 entry 都会将一个路径映射到一个后端服务或目标地址。

- `proxyPass`: 目标地址，可以是 Kubernetes Service 名称，也可以是完整的 URL。
- `proxyPassIsFullURL`: 若为 true，则将 `proxyPass` 视为完整 URL，并通过动态 Lua 逻辑进行转发。
- `headersFromSecret`: 从 Kubernetes Secret 中注入敏感请求头（如 API Key）。
- `enableUpstreamMetrics`: 启用 Prometheus 对该路由的指标采集。

以下是一个示例：
```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: Location
metadata:
  name: sample-location
  namespace: openresty-example
spec:
  entries:
    - path: /openai/
      proxyPass: https://openai-api/
      enableUpstreamMetrics: true
      accessLog: true
      extra:
        - "proxy_redirect off;"
        - "proxy_ssl_server_name on;"
    - path: /eth/
      proxyPass: https://eth-api/
      proxyPassIsFullURL: true
      enableUpstreamMetrics: true
      accessLog: true
      headersFromSecret:
        - headerName: apikey
          secretName: apikey
          secretKey: apikey
      extra:
        - "proxy_redirect off;"
        - "proxy_ssl_server_name on;"
    - path: /pay
      proxyPass: https://pay-api/
      proxyPassIsFullURL: true
      enableUpstreamMetrics: true
      accessLog: true
      extra:
        - "proxy_redirect off;"
        - "proxy_ssl_server_name on;"
```

## Upstream 示例

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: Upstream
metadata:
  name: demo-upstream
  namespace: openresty-example
spec:
  type: FullURL
  servers:
    - address: "https://api.example.com/v1/query"
      normalizeRequest:
        q:
          value: "$.keyword"
        page:
          lua: |
            return tostring(requestObj.page or 1)
```

> ℹ️ This Upstream uses `FullURL` mode and embeds inline normalization logic using JSONPath and Lua. It will be rendered as a Lua-based route in Nginx.



## NormalizeRule 示例

> ⚠️ `NormalizeRule` 仅对 `Upstream` 资源设置为 `type: FullURL` 时有效。
> 如果你使用的是传统的 proxyPass 路由（非 Lua 模式），此功能将不会生效。

本节展示了 NormalizeRule 的两个典型用法：  
1. 将请求体中的字段提取为查询参数（query）；
2. 对请求体进行结构重写（body），使其符合目标 API 格式。

> 两种可以同时用

### 示例一：提取uri参数

你可以通过 NormalizeRule 将请求体中的字段转换为 URL 查询参数。支持：

- 使用点路径（例如 `region.latitude`）提取嵌套字段；
- 使用 `value` 字段指定固定值；
- 使用 `queryFromSecret` 从 Kubernetes Secret 获取敏感值。

```yaml
## Original request body
## {
##   "city": "Taipei",
##   "region": {
##     "latitude": "25.0330",
##     "longitude": "121.5654"
##   }
## }

## Transformed into this real request:
## https://api.weatherapi.com/v1/forecast.json?q=Taipei&lat=25.0330&lon=121.5654&units=metric&appid=xxx
apiVersion: openresty.huangzehong.me/v1alpha1
kind: NormalizeRule
metadata:
  name: normalize-weather-query
  namespace: openresty-example
spec:
  request:
    query:
      q: "city"
      lat: "latitude"
      lon: "longitude"
      units:
        value: "metric"
      appid:
        queryFromSecret:
          secretName: weather-api-key
          secretKey: key
```

### 示例二：重写Body

当目标 API 要求特定的 JSON 请求结构时，可以使用 Lua 表达式生成所需内容。  
你可以访问 `requestObj` 获取原始请求体字段，组合成目标结构。此功能同样仅在 FullURL 模式下有效。

```json
{
  "out_trade_no": "ORD123456",
  "total_amount": "168.88",
  "currency": "CNY",
  "subject": "年货大礼包",
  "ext_user_info": {
    "name": "张三",
    "cert_no": "310101199001012345",
    "mobile": "13800138000",
    "cert_type": "IDENTITY_CARD"
  },
  "goods_detail": [
    {
      "goods_id": "SKU001",
      "goods_name": "坚果礼包",
      "price": "88.88",
      "quantity": 1
    },
    {
      "goods_id": "SKU002",
      "goods_name": "干果礼盒",
      "price": "80.00",
      "quantity": 1
    }
  ],
  "channel": "wechat",
  "campaign": "newyear"
}
```

会被转换为如下内部结构：

```json
{
  "orderNo": "ORD123456",
  "amount": 168.88,
  "currency": "CNY",
  "title": "年货大礼包",
  "user": {
    "id": "U9988",
    "name": "张三",
    "idCard": "310101199001012345",
    "mobile": "13800138000"
  },
  "products": [
    {
      "id": "SKU001",
      "name": "坚果礼包",
      "price": 88.88,
      "quantity": 1
    },
    {
      "id": "SKU002",
      "name": "干果礼盒",
      "price": 80.00,
      "quantity": 1
    }
  ],
  "extraInfo": {
    "channel": "wechat",
    "campaign": "newyear"
  }
}
```

> 💡 Lua 中的 `requestObj` 和 `responseObj` 分别表示原始请求和响应对象，仅在 FullURL 模式下可用。

NormalizeRule 可将上述结构映射到支付宝的 `bizContent` 格式：

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: NormalizeRule
metadata:
  name: normalize-alipay
  namespace: openresty-example
spec:
  request:
    body:
      orderNo: "out_trade_no"
    amount:
      lua: |
        return tonumber(requestObj.total_amount) or 0
    currency: "currency"
    title: "subject"
    user:
      lua: |
        return {
          id = "U9988",
          name = requestObj.ext_user_info.name,
          idCard = requestObj.ext_user_info.cert_no,
          mobile = requestObj.ext_user_info.mobile
        }
    products:
      lua: |
        local products = {}
        for _, item in ipairs(requestObj.goods_detail or {}) do
          table.insert(products, {
            id = item.goods_id,
            name = item.goods_name,
            price = tonumber(item.price) or 0,
            quantity = item.quantity
          })
        end
        return products
    extraInfo:
      lua: |
        return {
          channel = requestObj.channel,
          campaign = requestObj.campaign
        }
  response:
    payExpire: "data.payExpire"
    payUrl: "data.payUrl"
    payer:
      lua: |
        return {
          name = responseObj.data.payer.realName,
          id = responseObj.data.payer.userId
        }
    status: "data.status"
    transactionId: "data.transactionId"
```