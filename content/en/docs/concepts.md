---
title: Concepts
description: >
  Understand the custom resources used by OpenResty Operator.
weight: 3
---

{{% pageinfo %}}
This section introduces the core Custom Resources (CRDs) managed by OpenResty Operator, including what each CRD does and what Kubernetes resources it creates.
{{% /pageinfo %}}

## OpenResty

`OpenResty` defines the overall OpenResty instance, including the image, number of replicas, and references to `ServerBlock` resources.

**Creates:**
- A Kubernetes `Deployment` with shared process namespace
- A `ConfigMap` for `nginx.conf` (generated from linked CRDs)
- A `Pod` running OpenResty + reload agent
  - Monitors mounted ConfigMaps for changes
  - Automatically triggers `nginx -s reload` inside the container
  - Relies on shared PID namespace to control the Nginx master process directly
  - Also supports periodic reloads (e.g., every 10 seconds) to ensure consistency even if file change events are missed — similar to Redis AOF’s `everysec` strategy

👉 [See example ›](/docs/examples/#openresty-example)

---

## ServerBlock

`ServerBlock` defines a single Nginx `server` block, including port and referenced `Location` resources.

**Creates:**
- A `ConfigMap` containing one or more `server` blocks
- A Kubernetes `Service` corresponding to this server's `server_name`

Each `ServerBlock` maps to exactly one `Service`, and its `server_name` is composed of the resource name and namespace — resulting in the cluster DNS name used for internal routing (e.g., `demo-server.default.svc.cluster.local`).

👉 [See example ›](/docs/examples/#serverblock-example)

---

## Location

`Location` defines a single Nginx `location` block, typically with a `proxy_pass` directive to an external API.

**Creates:**
- A `ConfigMap` with the location-specific configuration file
- If `enableUpstreamMetrics` is set, it injects Lua code for Prometheus metrics

👉 [See example ›](/docs/examples/#location-example)

---

## Upstream

`Upstream` defines backend targets, supporting DNS-style `Address` or full URL-based routing (`FullURL` mode).

**Creates:**
- A Lua module or upstream block injected into `location` or `nginx.conf`
- Internal health-check results reported via metrics (if enabled)

👉 [See example ›](/docs/examples/#upstream-example)

---

## NormalizeRule

`NormalizeRule` defines request/response transformations for upstream APIs. It can be embedded or referenced via CRDs.

It supports parameter mapping based on JSONPath expressions and custom Lua scripts, allowing flexible transformation of incoming and outgoing payloads.

**Creates:**
- Lua snippets for normalizing request fields (query/path/header/body)
- Optional transformation logic for response shape alignment

👉 [See example ›](/docs/examples/#normalizerule-example)

---

Each CRD maps declaratively to configuration files that are composed into a unified `nginx.conf` deployed inside OpenResty Pods. These CRDs enable a modular, maintainable internal gateway architecture without manually editing Nginx config files.
