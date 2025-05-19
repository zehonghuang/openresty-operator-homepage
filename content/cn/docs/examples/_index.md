---
title: Examples
description: See your project in action with practical CRD configurations.
weight: 4
---

{{% pageinfo %}}
This section provides usage examples for each core CRD in OpenResty Operator.
Each block will include a representative YAML configuration and explanation.
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

本示例展示了如何将业务侧的支付请求转换为支付宝 `alipay.trade.app.pay` 接口所需的 `bizContent` 格式。

The original request JSON looks like this:

```json
{
  "orderNo": "70501111111S001111119",
  "amount": 9.0,
  "title": "大乐透",
  "products": [
    {
      "name": "ipad",
      "price": 2000,
      "quantity": 1,
      "id": "apple-01"
    }
  ],
  "user": {
    "name": "李明",
    "idCard": "362334768769238881",
    "mobile": "16587658765"
  }
}
```

> 💡 在 Lua 脚本中，`requestObj` 和 `responseObj` 是内置对象，分别表示原始请求和响应数据，可以通过标准 Lua 语法访问其字段。

And the NormalizeRule maps this structure into Alipay’s `bizContent` format:

```yaml
apiVersion: openresty.huangzehong.me/v1alpha1
kind: NormalizeRule
metadata:
  name: normalize-alipay
  namespace: openresty-example
spec:
  request:
    out_trade_no:
      value: "$.orderNo"
    total_amount:
      lua: |
        return string.format("%.2f", requestObj.amount)
    subject:
      value: "$.title"
    goods_detail:
      lua: |
        local goods = {}
        for _, item in ipairs(requestObj.products or {}) do
          table.insert(goods, {
            goods_name = item.name,
            price = tostring(item.price),
            quantity = item.quantity,
            goods_id = item.id,
          })
        end
        return goods
    ext_user_info:
      lua: |
        return {
          name = requestObj.user.name,
          cert_no = requestObj.user.idCard,
          mobile = requestObj.user.mobile,
          cert_type = "IDENTITY_CARD"
        }
```
