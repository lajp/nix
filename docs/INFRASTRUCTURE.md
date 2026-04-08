# Infrastructure Overview

6 NixOS hosts across 3 physical locations, connected via a self-hosted Headscale/Tailscale mesh VPN.

## Host Topology

```mermaid
graph TD
    internet((Internet))

    subgraph hetzner["Hetzner Cloud"]
        ankka["<b>ankka</b> (aarch64)<br/>Central Services<br/>37.27.191.46<br/>Tailnet: 100.64.0.4"]
    end

    subgraph home["Home Network — 192.168.1.0/24"]
        router["Router<br/>192.168.1.1"]
        nas["<b>nas</b> (x86_64)<br/>HP Microserver<br/>Media & Storage<br/>Tailnet: 100.64.0.2<br/>iLO: 192.168.1.38"]
        proxypi["<b>proxy-pi</b> (aarch64)<br/>DNS & Reverse Proxy<br/>Tailnet: 100.64.0.3"]
        framework["<b>framework</b> (x86_64)<br/>Daily Driver Laptop"]
        t480["<b>t480</b> (x86_64)<br/>ThinkPad Laptop"]
    end

    subgraph vaasa["Vaasa Network — 192.168.178.0/24"]
        vaasanas["<b>vaasanas</b> (x86_64)<br/>Secondary Server"]
    end

    ankka ---|Public IP| internet
    router --- internet

    nas <-..->|Tailscale| ankka
    proxypi <-..->|Tailscale| ankka
    framework <-..->|Tailscale| ankka
    t480 <-..->|Tailscale| ankka
    vaasanas <-..->|Tailscale| ankka

    framework -.-|WireGuard VPN| vaasa
```

### Host Roles

| Host | Location | Arch | Type | Key Role |
|------|----------|------|------|----------|
| **ankka** | Hetzner (Helsinki) | aarch64 | Server | Central control plane: Prometheus, Grafana, Headscale, mail, Matrix, HedgeDoc, Gatus, CoreDNS, website |
| **nas** | Home | x86_64 | Server | HP Microserver (iLO at .38): Jellyfin, nixarr stack, Nextcloud, Syncthing, Samba, Attic cache, ZFS, NVIDIA GPU, UPS |
| **proxy-pi** | Home | aarch64 | Server | Network edge: AdGuard Home DNS, nginx reverse proxy for internal services |
| **vaasanas** | Vaasa | x86_64 | Server | Secondary storage: NFS server, Samba, ZFS |
| **framework** | Mobile | x86_64 | Desktop | Daily driver: Framework 13 AMD, Niri compositor, multiple VPNs, Docker |
| **t480** | Mobile | x86_64 | Desktop | Secondary laptop: ThinkPad T480, Niri compositor, PIA VPN |

## DNS Resolution

```mermaid
flowchart LR
    clients["Tailnet Clients"]
    coredns["<b>CoreDNS</b><br/>ankka<br/>100.64.0.4:53"]
    adguard["<b>AdGuard Home</b><br/>proxy-pi<br/>100.64.0.3:53"]
    upstream1["1.1.1.1"]
    upstream2["8.8.8.8"]

    clients -->|DNS queries| coredns
    coredns -->|"primary (sequential)"| adguard
    coredns -->|fallback| upstream1
    adguard -->|upstream| upstream1
    adguard -->|upstream| upstream2
```

- Headscale configures `100.64.0.4` (CoreDNS on ankka) as the nameserver for the tailnet.
- **CoreDNS** receives all tailnet DNS queries and forwards them sequentially: first to AdGuard Home, falling back to 1.1.1.1 if unreachable.
- **AdGuard Home** (proxy-pi) provides ad-blocking and filtering, forwarding to upstream resolvers.

## Service Map

```mermaid
graph LR
    subgraph ankka_svc["ankka — Public Services"]
        headscale["Headscale<br/><i>headscale.lajp.fi</i>"]
        prometheus["Prometheus<br/><i>central, :9090</i>"]
        grafana["Grafana<br/><i>grafana.lajp.fi</i>"]
        gatus["Gatus<br/><i>status.lajp.fi</i>"]
        mail["Mail Server<br/><i>mail.portfo.rs</i>"]
        matrix["Matrix Synapse<br/><i>matrix.lajp.fi</i>"]
        element["Element Web<br/><i>element.lajp.fi</i>"]
        hedgedoc["HedgeDoc<br/><i>pad.lajp.fi</i>"]
        website["Website<br/><i>lajp.fi</i>"]
        cheese["CHEESE Ilmomasiina<br/><i>cheese.lajp.fi</i>"]
        esn_ical["ESN iCal<br/><i>esn-ical.lajp.fi</i>"]
        coredns_svc["CoreDNS"]
        telegram["Email-Telegram<br/>Bridge"]
    end

    subgraph nas_svc["nas — Media & Storage"]
        jellyfin["Jellyfin<br/><i>jellyfin.lajp.fi</i>"]
        nextcloud["Nextcloud<br/><i>pilvi.lajp.fi</i>"]
        nixarr["nixarr Stack<br/><i>Sonarr, Radarr, Prowlarr,<br/>Bazarr, Lidarr, Jellyseerr</i>"]
        transmission["Transmission<br/><i>PIA VPN namespace</i>"]
        attic["Attic Cache<br/><i>cache.lajp.fi</i>"]
        vaultwarden["Vaultwarden<br/><i>vault.intra.lajp.fi</i>"]
        syncthing["Syncthing"]
        samba_nas["Samba"]
    end

    subgraph proxypi_svc["proxy-pi — DNS & Proxy"]
        adguard_svc["AdGuard Home<br/><i>adguard.intra.lajp.fi</i>"]
        nginx_proxy["nginx Reverse Proxy<br/><i>*.intra.lajp.fi</i>"]
    end

    subgraph vaasanas_svc["vaasanas — Secondary Storage"]
        nfs_vaa["NFS Server<br/><i>exports to 192.168.178.0/24</i>"]
        samba_vaa["Samba"]
    end
```

## Monitoring Architecture

```mermaid
flowchart TD
    subgraph agents["Prometheus Agents (remote_write)"]
        nas_agent["<b>nas</b><br/>node, nginx, smartctl, zfs,<br/>nvidia-gpu, apcupsd"]
        proxypi_agent["<b>proxy-pi</b><br/>node, nginx"]
        vaasanas_agent["<b>vaasanas</b><br/>node"]
    end

    central["<b>Central Prometheus</b><br/>ankka:9090<br/>8GB retention"]

    nas_agent -->|remote_write<br/>100.64.0.4:9090| central
    proxypi_agent -->|remote_write| central
    vaasanas_agent -->|remote_write| central

    subgraph ankka_local["ankka Local Scrapes"]
        dovecot["dovecot"]
        rspamd["rspamd"]
        postfix["postfix"]
        synapse_exp["synapse"]
        hedgedoc_exp["hedgedoc"]
        headscale_exp["headscale"]
        node_ankka["node_exporter"]
        nginx_ankka["nginx + nginxlog"]
    end

    ankka_local --> central

    central --> grafana_dash["<b>Grafana</b><br/>11 Dashboards"]

    gatus_mon["<b>Gatus</b><br/>status.lajp.fi<br/>30+ endpoint checks<br/><i>(independent, not fed by Prometheus)</i>"]
    gatus_mon -->|email alerts| telegram["Email-Telegram Bridge"]
```

### Grafana Dashboards

| Dashboard | Metrics Source |
|-----------|---------------|
| nixos-nodes | node_exporter (all hosts) |
| nginx | nginx exporter |
| nginx-analytics | nginx-log exporter (JSON logs) |
| email | dovecot, rspamd, postfix |
| gpu | nvidia-gpu exporter (nas) |
| smart | smartctl exporter (nas) |
| zfs | zfs exporter (nas) |
| ups | apcupsd exporter (nas) |
| headscale | headscale metrics (ankka) |
| hedgedoc | hedgedoc metrics (ankka) |
| synapse | matrix synapse metrics (ankka) |

## Backup Strategy

```mermaid
flowchart LR
    framework_bk["<b>framework</b><br/>/home/lajp"]
    t480_bk["<b>t480</b><br/>/home/lajp"]
    nas_bk["<b>nas</b><br/>/media/luukas/Backups"]
    nas_zfs["<b>nas</b><br/>ZFS pool snapshots"]
    gdrive["Google Drive"]
    syncthing_devices["Synced Devices"]
    nas_syncthing["<b>nas</b><br/>Syncthing"]

    framework_bk -->|"Restic / SFTP<br/>daily (random 5h delay)<br/>24h/30d/4w/6m/3y retention"| nas_bk
    t480_bk -->|"Restic / SFTP<br/>daily"| nas_bk
    nas_zfs -->|"rclone<br/>daily incremental<br/>quarterly full"| gdrive
    nas_syncthing <-->|"Syncthing<br/>continuous"| syncthing_devices
```

- **Restic** backs up `/home/lajp` from desktops to nas via SFTP. Excludes `.cache`, databases, and large repos.
- **ZFS backup** sends incremental snapshots to Google Drive via rclone. Uses ZFS holds to track state.
- **Syncthing** provides continuous file sync on nas.
- **backup-notify** sets a failure wallpaper if restic backup fails (enabled on framework).

## Domains & Certificates

### Public Domains (ankka — ACME/Let's Encrypt)

| Domain | Service |
|--------|---------|
| `lajp.fi` | Website + Matrix .well-known delegation |
| `headscale.lajp.fi` | Headscale VPN control |
| `grafana.lajp.fi` | Grafana dashboards |
| `status.lajp.fi` | Gatus status page |
| `pad.lajp.fi` | HedgeDoc collaborative notes |
| `matrix.lajp.fi` | Matrix Synapse homeserver |
| `element.lajp.fi` | Element Web client |
| `cheese.lajp.fi` | Cheese ilmomasiina |
| `esn-ical.lajp.fi` | ESN calendar service |
| `luuk.as` | Placeholder page |

### Public Domains (nas — DynDNS + ACME)

| Domain | Service |
|--------|---------|
| `jellyfin.lajp.fi` | Jellyfin media server |
| `jellyseerr.lajp.fi` | Jellyseerr request interface |
| `pilvi.lajp.fi` | Nextcloud |
| `cache.lajp.fi` | Attic binary cache |

### DynDNS Only (vaasanas)

| Domain | Service |
|--------|---------|
| `mc.portfo.rs` | DynDNS record (no nginx) |

### Internal Domains (proxy-pi — Cloudflare DNS wildcard cert)

| Domain | Proxied To |
|--------|-----------|
| `adguard.intra.lajp.fi` | AdGuard Home (localhost) |
| `ilo.intra.lajp.fi` | iLO on nas (192.168.1.38) |
| `router.intra.lajp.fi` | Router (192.168.1.1) |
| `vault.intra.lajp.fi` | Vaultwarden (192.168.1.35:8222) |

## Mail Server

FQDN: `mail.portfo.rs` (ankka). Uses simple-nixos-mailserver with rspamd spam filtering.

| Domain | Purpose |
|--------|---------|
| `lajp.fi` | Primary personal |
| `portfo.rs` | Family |
| `formicer.com` | Organization |
| `nextcloud.otanix.fi` | Service notifications |
| `oy.lajp.fi` | Business |

Accounts: one main account on lajp.fi, plus send-only accounts for alerts (monitored by email-telegram bridge), nextcloud notifications, and no-reply.

## Network Segments

| Segment | CIDR | Hosts | Notes |
|---------|------|-------|-------|
| Home LAN | 192.168.1.0/24 | nas, proxy-pi, framework, t480 | Router at .1, nas iLO at .38, Vaultwarden at .35 |
| Vaasa LAN | 192.168.178.0/24 | vaasanas | Accessible from framework via WireGuard |
| Tailnet | 100.64.0.0/10 | All hosts | Managed by Headscale on ankka |
| Hetzner Public | 37.27.191.46/32 | ankka | Public-facing services |
