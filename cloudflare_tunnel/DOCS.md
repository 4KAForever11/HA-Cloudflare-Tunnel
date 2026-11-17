# Cloudflare Tunnel Add-on / Cloudflare Tunnel 加载项

## English

### Connect the tunnel and origin

Copy the token for your remotely-managed Cloudflare Tunnel into the add-on Configuration tab. Configure the public hostname in Cloudflare with a service such as `http://<HOME_ASSISTANT_LAN_IP>:8123`. Use the port actually configured on your HA instance. Private HTTP can coexist with public HTTPS; `localhost` inside the add-on refers to the connector container.

A healthy tunnel means the connector reached Cloudflare. It does not prove Home Assistant accepts forwarded requests. Keep Home Assistant authentication enabled. Start the add-on and make an initial hostname request to identify the proxy in HA logs if it is rejected; complete reverse-proxy setup below, then verify the login page.

### Home Assistant 2026.8 and later

1. Open **Settings → System → Network → HTTP server → Reverse proxy**.
2. Enable **Trust X-Forwarded-For**.
3. Add the connector's observed source IP to **Trusted proxies**, preserving existing entries. Use a verified add-on CIDR only if needed for changing container addresses; CIDRs must use the network address. Do not trust every address.
4. Save. Home Assistant restarts; reconnect and confirm the settings within **5 minutes**, or they roll back.

HTTP YAML is imported once during migration; subsequent `http:` edits are ignored. Verify the UI values, then remove obsolete HTTP YAML following the repair instructions. Do not edit or delete `.storage/http` during normal setup.

### Before Home Assistant 2026.8

For versions that still read HTTP configuration from YAML, merge this into the existing `http:` section. Replace the placeholder with the actual proxy IP before saving:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - "REPLACE_WITH_PROXY_IP_FROM_HA_LOG"
```

Preserve other HTTP settings and trusted proxies. If using `http: !include http.yaml`, edit the included file without another `http:` wrapper. Check configuration and restart **Home Assistant Core**, not just this add-on. This YAML procedure is not the configuration method for migrated installations.

### Diagnose HTTP 400

Visit the public hostname once and inspect the matching Home Assistant Core log:

- `HTTP integration is not set-up for reverse proxies`: enable forwarded-header trust and add the proxy.
- `Received X-Forwarded-For header from an untrusted proxy ...`: add the reported proxy address to the active configuration.

The address must come from a real hostname request. A test request sent directly from another LAN computer reports that computer, not cloudflared. Do not substitute the browser client, Cloudflare edge, or origin LAN address without checking the log. A typical HAOS Supervisor subnet may be `172.30.32.0/23`, but verify your network before using it; do not copy it blindly. Existing loopback entries are not a replacement for the connector's address.

After applying the settings, verify that the public HTTPS hostname opens the HA login page. Do not strip forwarding headers or disable authentication to bypass the check.

### Other failures

- **Token required**: save the token in the add-on Configuration tab.
- **Tunnel offline**: check the token and outbound DNS, plus port 7844/UDP (QUIC) or 7844/TCP (HTTP/2).
- **502**: check origin reachability, protocol and port.
- **403**: inspect Cloudflare Access/WAF policy and the response; it is distinct from HA proxy-trust 400.
- **WebSocket/login issues**: check hostname routing and conflicting proxy/cache rules.

Enable **Start on boot** and **Watchdog** for the add-on. Install binary updates through Supervisor. Rotate exposed tokens in Cloudflare and update the add-on configuration.

Reference: [Home Assistant HTTP settings and YAML migration](https://www.home-assistant.io/integrations/http/).

## 简体中文

### 连接隧道与源站

将已有远程管理型 Cloudflare Tunnel 的 Token 填入加载项配置页。在 Cloudflare 中配置公开主机名及 Service，例如 `http://<HOME_ASSISTANT_LAN_IP>:8123`。端口须与 HA 实际监听端口一致。内网 HTTP 与公网 HTTPS 可以同时使用；加载项内的 `localhost` 指连接器容器自身。

Tunnel 健康只代表连接器已连接 Cloudflare，不能证明 HA 接受转发请求。保留 HA 登录认证。先启动加载项并访问一次域名；若被拒绝，从对应 HA 日志取得代理地址，再按下文配置信任，最后验证登录页。

### Home Assistant 2026.8 及以后

1. 打开**设置 → 系统 → 网络 → HTTP 服务器 → 反向代理**。
2. 启用**信任 X-Forwarded-For**。
3. 在**信任的代理**中添加连接器实际来源 IP，保留已有条目。若容器地址会变化，可使用经过核实的加载项 CIDR 子网；CIDR 应填写网络地址，不要信任全部地址。
4. 保存后 HA 会重启。恢复连接后，按提示在 **5 分钟内确认新设置**，否则会回退。

HTTP YAML 仅在迁移时导入一次，之后继续修改 `http:` 段会被忽略。先核对界面设置，再按修复提示移除过时的 HTTP YAML。正常配置应使用界面，不要直接修改或删除 `.storage/http`。

### Home Assistant 2026.8 之前

仅对仍从 YAML 读取 HTTP 配置的旧版本，将以下内容合并到已有 `http:` 节，并在保存前将占位符替换为实际代理 IP：

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - "REPLACE_WITH_PROXY_IP_FROM_HA_LOG"
```

保留其他 HTTP 设置和已有代理。如果使用 `http: !include http.yaml`，应修改被引用文件，且不要重复添加 `http:` 包装。检查配置后重启 **Home Assistant Core**，仅重启加载项无效。已经迁移的实例不应继续使用此 YAML 配置方法。

### 排查 HTTP 400

通过公开域名访问一次，在 Home Assistant Core 日志中找到对应报错：

- `HTTP integration is not set-up for reverse proxies`：启用转发头信任并添加代理地址。
- `Received X-Forwarded-For header from an untrusted proxy ...`：将日志中的代理地址加入当前生效的配置。

地址必须来自真实域名请求。其他局域网电脑直发转发头产生的日志会显示那台电脑，而非 cloudflared。不要未经核实就填入浏览器客户端地址、Cloudflare 边缘地址或源站局域网地址。常见 HAOS Supervisor 子网可能是 `172.30.32.0/23`，但必须先确认自己的网络，不能盲目照抄；已有的回环地址也不能替代连接器地址。

配置生效后，通过公网 HTTPS 域名确认 HA 登录页正常显示。不要删除转发头或关闭登录认证来绕过检查。

### 其他问题

- **提示需要 Token**：在加载项配置页填写并保存 Token。
- **Tunnel 离线**：检查令牌、出站 DNS，以及 7844/UDP（QUIC）或 7844/TCP（HTTP/2）。
- **502**：检查源站是否可达、协议及端口是否正确。
- **403**：检查 Cloudflare Access/WAF 策略及响应内容，不能按 HA 代理信任 400 来处理。
- **WebSocket/登录异常**：检查域名路由及冲突的代理、缓存规则。

在加载项页面启用**开机启动**和**看门狗**，通过 Supervisor 安装二进制更新。令牌泄露后在 Cloudflare 中轮换并更新加载项配置。

参考：[Home Assistant 官方 HTTP 设置及 YAML 迁移说明](https://www.home-assistant.io/integrations/http/)。
