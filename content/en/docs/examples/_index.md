---
title: Examples
description: See your project in action with practical CRD configurations.
weight: 4
---

{{% pageinfo %}}
This section provides usage examples for each core CRD in OpenResty Operator.
Each block will include a representative YAML configuration and explanation.
{{% /pageinfo %}}

## OpenResty Example

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

## ServerBlock Example

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

> ℹ️ Each `ServerBlock` corresponds to one Kubernetes Service with DNS name `<name>.<namespace>.svc.cluster.local`. This name is automatically used as the `server_name` directive for the Nginx server block.


## Location Example


## Upstream Example

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



## NormalizeRule Example

This NormalizeRule transforms a business-side payment request into the structure expected by Alipay’s `alipay.trade.app.pay` API.

Here is an example incoming request:

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

is transformed into this internal format:

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

> 💡 In Lua blocks, `requestObj` and `responseObj` are built-in objects that represent the original request and response payloads. You can access and manipulate their fields using standard Lua syntax.

And the NormalizeRule maps this structure into Alipay’s `bizContent` format:

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
