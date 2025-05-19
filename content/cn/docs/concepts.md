---
title: 核心概念
description: >
  了解 OpenResty Operator 所使用的自定义资源（CRD）。
weight: 3
---

{{% pageinfo %}}
本节介绍 OpenResty Operator 管理的核心自定义资源（CRD），包括每个 CRD 的作用以及它在 Kubernetes 中创建的相关资源。
{{% /pageinfo %}}

## OpenResty

`OpenResty` 定义了一个完整的 OpenResty 实例，包括所使用的镜像、副本数量，以及所引用的 `ServerBlock` 资源。

**创建的资源：**
- 一个带有共享进程命名空间的 Kubernetes `Deployment`
- 一个组合所有引用 CRD 渲染出的 `nginx.conf` 配置的 `ConfigMap`
- 一个包含 OpenResty 和轻量级 reload-agent 的 Pod：
  - 监听挂载的 ConfigMap 是否变更
  - 变更后自动在容器中执行 `nginx -s reload`
  - 借助共享 PID 命名空间直接控制 Nginx 主进程
  - 同时支持周期性 reload（如每 10 秒执行一次），即使错过事件也能保证配置一致 —— 类似 Redis AOF 的 `everysec` 策略

👉 [See example ›](/cn/docs/examples/#openresty-example)

---

## ServerBlock

`ServerBlock` 定义了一个 Nginx 的 `server` 区块，包括监听端口和所引用的 `Location` 列表。

**创建的资源：**
- 一个包含一个或多个 server 配置块的 `ConfigMap`
- 一个 Kubernetes `Service`，其名称与该 ServerBlock 的 `server_name` 对应

每个 `ServerBlock` 都对应一个独立的 `Service`，其 `server_name` 会由 CR 的名称和命名空间组合生成，从而形成集群内部的 DNS 域名，例如：`demo-server.default.svc.cluster.local`。

👉 [See example ›](/cn/docs/examples/#serverblock-example)

---

## Location

`Location` 定义了一个 Nginx 的 `location` 区块，通常包括一个 `proxy_pass` 到外部 API。

**创建的资源：**
- 一个独立的 `ConfigMap`，包含该 location 的具体配置文件
- 如果启用了 `enableUpstreamMetrics`，会自动注入 Lua 代码以支持 Prometheus 指标采集

👉 [See example ›](/cn/docs/examples/#location-example)

---

## Upstream

`Upstream` 定义后端服务目标，支持 DNS 地址模式（Address）或完整 URL 路由模式（FullURL）。

**创建的资源：**
- 注入到 `location` 或 `nginx.conf` 的 Lua 模块或 Nginx upstream 配置块
- 如果启用了健康检查，会将其状态通过指标系统上报

👉 [See example ›](/cn/docs/examples/#upstream-example)

---

## NormalizeRule

`NormalizeRule` 定义了上游 API 的请求和响应结构转换规则，可以被其他 CRD 引用或嵌入。

**创建的资源：**
- 处理请求字段（query/path/header/body）的 Lua 脚本片段
- 可选的响应归一化转换逻辑

👉 [See example ›](/cn/docs/examples/#normalizerule-example)

---

每个 CRD 都会被声明式地渲染成配置片段，并最终组合为完整的 `nginx.conf`，挂载至 OpenResty Pod 内运行。  
通过这些 CRD，用户可以以模块化、声明式的方式构建一个可维护的内部 API 网关，而无需手动编辑 Nginx 配置文件。
