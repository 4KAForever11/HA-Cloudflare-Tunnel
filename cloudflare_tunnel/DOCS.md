# Cloudflare Tunnel Add-on / Cloudflare Tunnel 加载项

## English

### Create the tunnel

In Cloudflare Zero Trust, create or select a remotely-managed tunnel. Open the tunnel's install/run instructions and copy its token. In Home Assistant, paste the token into this add-on's **Configuration > Tunnel token** field, save, and start the add-on. The token is stored as a password option and is not printed by the entrypoint.

### Route a hostname

In the tunnel's **Public Hostnames** page, add the hostname you want to publish and point its service to the private origin. For Home Assistant, an example is `http://<HOME_ASSISTANT_LAN_IP>:8123`. This connector opens outbound connections to Cloudflare; it does not need an inbound port on your router.

For Home Assistant to accept forwarded client addresses, configure the HTTP integration's `use_x_forwarded_for: true` and set `trusted_proxies` to the actual source subnet used by the add-on network. Home Assistant logs identify untrusted proxy addresses. Trust only that private subnet, then restart Home Assistant. Do not use `0.0.0.0/0` or `::/0`.

Merge this into the existing `http:` section of `/config/configuration.yaml`; do not create a duplicate section. Replace the example proxy IP with the address Home Assistant logs report:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.30.33.2
```

The address above is an example, not a fixed add-on IP. Use your observed address or a verified add-on subnet. Check configuration and restart Home Assistant. Enable **Start on boot** and **Watchdog** on the add-on page. Keep Home Assistant authentication enabled. A healthy tunnel only proves the connector reached Cloudflare; open your HTTPS hostname to verify origin access.

If Home Assistant uses HTTPS on port 8123, select an HTTPS origin with a valid certificate. `localhost` inside this add-on refers to the connector container. Outbound tunnel traffic needs port **7844/UDP** for QUIC or **7844/TCP** for HTTP/2, plus DNS and HTTPS for setup. The connector does not update its binary at runtime; install add-on updates through Supervisor.

### Troubleshooting

- **Token required**: paste the token from the selected remotely-managed tunnel and save the add-on configuration.
- **Tunnel does not connect**: confirm outbound DNS and HTTPS/QUIC access, verify that the token belongs to the intended tunnel, and inspect add-on logs.
- **Cloudflare returns 502**: verify that the Public Hostname service URL is reachable from the HAOS host and uses the correct scheme and port.
- **Home Assistant reports an untrusted proxy**: add only the source subnet shown in Home Assistant logs to `trusted_proxies`.
- **WebSocket or login issues**: confirm the hostname points directly to Home Assistant and remove conflicting proxy rules while testing.

To rotate a token that may have been exposed, rotate it in Cloudflare Zero Trust and update the add-on configuration.

## 简体中文

### 创建 Tunnel

在 Cloudflare Zero Trust 中创建或选择一个远程管理型 Tunnel，打开其安装/运行说明并复制 Token。回到 Home Assistant，将 Token 填入本加载项的 **配置 > Tunnel token**，保存并启动。Token 以密码配置项保存，入口脚本不会将其写入日志。

### 配置域名路由

在 Tunnel 的 **Public Hostnames（公开主机名）** 页面添加需要公开的域名，并将 Service 指向内网源站。Home Assistant 示例：`http://<HOME_ASSISTANT_LAN_IP>:8123`。连接器主动向 Cloudflare 建立出站连接，路由器不需要开放入站端口。

若需要 Home Assistant 识别转发后的客户端地址，请在 HTTP 集成中设置 `use_x_forwarded_for: true`，并将 `trusted_proxies` 设置为加载项网络实际使用的来源子网。Home Assistant 日志会显示未受信任代理地址。只信任该内网子网后重启 Home Assistant；不要使用 `0.0.0.0/0` 或 `::/0`。

将以下内容合并到 `/config/configuration.yaml` 已有的 `http:` 节中，不要重复创建同名节。将示例代理地址替换为 Home Assistant 日志实际报告的来源地址：

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.30.33.2
```

此地址仅是示例，不是固定的加载项地址；应使用实际观察到的地址或已确认的加载项子网。检查配置后重启 Home Assistant，在加载项页面启用**开机启动**和**看门狗**。保留 Home Assistant 登录认证。Tunnel 显示健康只证明连接器已连接 Cloudflare，还需打开自己的 HTTPS 域名验证源站可访问。

如果 Home Assistant 的 8123 端口使用 HTTPS，请选择 HTTPS 源站并使用有效证书。加载项内的 `localhost` 指连接器容器自身。隧道需要出站 **7844/UDP**（QUIC）或 **7844/TCP**（HTTP/2），以及设置所需的 DNS、HTTPS 连接。运行期间关闭二进制自动更新，通过 Supervisor 安装加载项更新。

### 故障排查

- **提示需要 Token**：粘贴所选远程管理型 Tunnel 的 Token，并保存加载项配置。
- **Tunnel 无法连接**：确认网络允许出站 DNS 及 HTTPS/QUIC，检查 Token 是否属于目标 Tunnel，并查看加载项日志。
- **Cloudflare 返回 502**：检查 Public Hostname 中的 Service URL 是否能从 HAOS 主机访问，以及协议和端口是否正确。
- **Home Assistant 提示代理不受信任**：只把 Home Assistant 日志显示的来源子网加入 `trusted_proxies`。
- **WebSocket 或登录异常**：确认域名直接指向 Home Assistant，排查时先移除冲突的代理规则。

如果 Token 可能已泄露，请在 Cloudflare Zero Trust 轮换 Token，并同步更新加载项配置。
