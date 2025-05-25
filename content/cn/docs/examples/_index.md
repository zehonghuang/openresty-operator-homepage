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

以下 NormalizeRule 将业务侧支付请求转换为支付宝 `alipay.trade.app.pay` 接口所需的参数结构：

下面是一个示例请求：

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

转换后的真实结构如下：

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

> 💡 在 Lua 块中，`requestObj` 与 `responseObj` 是内置对象，分别代表原始请求和响应的 JSON 数据，可使用标准 Lua 语法进行字段访问与处理。

NormalizeRule 将该结构映射为支付宝 `bizContent` 格式：

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: NormalizeRule
metadata:
  name: normalize-alipay
  namespace: openresty-example
spec:
  request:
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