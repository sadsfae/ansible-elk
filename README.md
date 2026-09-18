# ansible-elk

Ansible Playbook for setting up the ELK/EFK Stack and Filebeat client on remote hosts

![ELK](/image/ansible-elk.png?raw=true)

[![GA](https://github.com/sadsfae/ansible-elk/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/sadsfae/ansible-elk/actions)

<!--toc:start-->

- [ansible-elk](#ansible-elk)
  - [Branch and Version Guide](#branch-and-version-guide)
  - [What does it do?](#what-does-it-do)
  - [Requirements](#requirements)
    - [Supported Operating Systems](#supported-operating-systems)
    - [Hardware Requirements](#hardware-requirements)
    - [Software Requirements](#software-requirements)
  - [Notes](#notes)
  - [Security and Authentication](#security-and-authentication)
    - [Authentication Architecture](#authentication-architecture)
    - [Production Security Considerations](#production-security-considerations)
  - [Migration from 6.x to 9.x](#migration-from-6x-to-9x)
    - [Key Breaking Changes in ES 9.x](#key-breaking-changes-in-es-9x)
  - [ELK/EFK Server Instructions](#elkefk-server-instructions)
    - [Create your Kibana Index Pattern](#create-your-kibana-index-pattern)
  - [ELK Client Instructions](#elk-client-instructions)
  - [Legacy ELK Versions](#legacy-elk-versions)
    - [Elasticsearch 6.x (RHEL7 Compatible)](#elasticsearch-6x-rhel7-compatible)
    - [Elasticsearch 5.6 (Legacy)](#elasticsearch-56-legacy)
    - [Elasticsearch 2.4 (Legacy)](#elasticsearch-24-legacy)
    - [Video Tutorial](#video-tutorial)
  - [File Hierarchy](#file-hierarchy)
  <!--toc:end-->

> [!IMPORTANT]
> **Major Version Update:** We now deploy **Elasticsearch 9.x** with significant changes:
>
> - **RHEL/CentOS 7 is NO LONGER SUPPORTED** (use `6.8` or older branches for EL7)
> - Requires **Java 17** (automatically installed)
> - Minimum supported OS: **RHEL/Rocky 8+**, **Ubuntu 20.04+**, **Debian 11+**
> - Breaking configuration changes from 6.x/7.x - review migration notes below

## Branch and Version Guide

Choose the appropriate branch based on your OS and desired Elasticsearch version:

| Branch   | ELK Version | Supported OS                                 | Java Version | Use Case                                   |
| -------- | ----------- | -------------------------------------------- | ------------ | ------------------------------------------ |
| `master` | **9.x**     | RHEL/Rocky 8+, Ubuntu 20.04+ LTS, Debian 11+ | Java 17      | **Latest features**, modern platforms only |
| `6.8`    | **6.x**     | RHEL7/CentOS7, RHEL8+, Rocky, Fedora         | Java 8       | **RHEL7 support**, stable production       |
| `5.6`    | **5.x**     | RHEL7/CentOS7+                               | Java 8       | Legacy deployments                         |
| `2.4`    | **2.x**     | RHEL7/CentOS7+                               | Java 8       | Very old/resource-constrained systems      |

> [!IMPORTANT]
> Only the `master` branch is _supported_, although older branches may likely work they are not maintained or tested.

> [!NOTE]
> **For RHEL7/CentOS7 users:** Use `6.8` branch. The `master` branch (9.x) requires Java 17 which is not available on EL7.
>
> **Switching branches:**
>
> ```bash
> git clone https://github.com/sadsfae/ansible-elk
> cd ansible-elk
> git checkout 6.8          # For EL7 with Elasticsearch 6.x
> # OR
> git checkout 5.6          # For older Elasticsearch 5.x
> # OR
> git checkout 2.4          # For legacy Elasticsearch 2.x
> ```

## What does it do?

- Automated deployment of a single-node full **9.x series** ELK or EFK stack (Elasticsearch, Logstash/Fluentd, Kibana)
  - Uses Nginx as a reverse proxy for Kibana, or optionally Apache via `apache_reverse_proxy: true`
  - Generates SSL certificates for Filebeat or Logstash-forwarder
  - Adds either iptables or firewalld rules if firewall is active
  - Tunes Elasticsearch heapsize to half your memory, to a max of 32G
  - Deploys ELK clients using SSL and Filebeat for Logstash (Default)
  - Deploys rsyslog if Fluentd is chosen over Logstash, picks up
    the same set of OpenStack-related logs in /var/log/\*
  - All service ports can be modified in `install/group_vars/all.yml`
  - Optionally install [curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html)
  - This is also available on [Ansible Galaxy](https://galaxy.ansible.com/sadsfae/ansible-elk/)

## Requirements

### Supported Operating Systems

- **RHEL/Rocky Linux:** 8, 9, 10
- **Ubuntu LTS:** 20.04 (Focal), 22.04 (Jammy), 24.04 (Noble)
- **Debian:** 11 (Bullseye), 12 (Bookworm)

### Hardware Requirements

- ELK/EFK server with at least **8GB of memory** (16GB+ recommended for production)
- Elasticsearch 9.x is more resource-intensive than older versions
- You may want to modify `vm.swappiness` as ELK/EFK is demanding and swapping kills responsiveness:

```bash
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p
```

### Software Requirements

- **Java 17** - Automatically installed by the playbook (OpenJDK headless)
- **Ansible 2.9+** for playbook execution
- Python 3 on target systems

## Notes

- Current ELK version is **9.x** - major upgrade from previous 6.x series
- Sets the nginx htpasswd to admin/admin initially (see [Security and Authentication](#security-and-authentication) section)
- Elasticsearch security disabled by default for dev/test deployments
- nginx ports default to 80/8080 for Kibana and SSL cert retrieval (configurable)
- Uses OpenJDK 17 for Java (required for ES 9.x)
- Deployment takes around 3-5 minutes on a test VM
- Fluentd can be substituted for the default Logstash
  - Set `logging_backend: fluentd` in `group_vars/all.yml`
  - **Platform Support:** Fluentd backend (fluent-package v6 LTS) is supported on:
    - RHEL/Rocky Linux 8, 9
    - Debian 12 (Bookworm) and newer
    - Ubuntu 22.04 (Jammy) and newer
  - **Auto-Fallback:** On unsupported platforms (RHEL 10, Debian 11, Ubuntu 20.04), the playbook automatically uses Logstash backend with a warning message
  - Logstash backend (default) works on **all** supported platforms
- Install curator by setting `install_curator_tool: true` in `install/group_vars/all.yml`
- **X-Pack Note**: As of Elasticsearch 6.3+, X-Pack features are built directly into the stack and no longer require separate plugin installation. Security, monitoring, and other features can be enabled via configuration in `elasticsearch.yml`. When security is enabled, set `install_elasticsearch_xpack: true` so the logstash role authenticates to Elasticsearch when loading the filebeat index template.

## Security and Authentication

This playbook is designed for **development and testing environments** with a simplified security model:

### Authentication Architecture

- **Kibana Web Access**: Protected by HTTP Basic Auth via nginx reverse proxy
  - Default credentials: `admin` / `admin` (configurable in `install/group_vars/all.yml`)
  - Change `kibana_user` and `kibana_password` for custom credentials
- **Elasticsearch API**: Security disabled by default (`xpack.security.enabled: false`)
  - Elasticsearch listens on localhost:9200 without authentication
  - Safe for single-server dev/test deployments behind a firewall
  - For production, enable ES security and configure TLS (see Production Security below)

### Production Security Considerations

> [!WARNING]
> The default configuration is **NOT suitable for production** or internet-exposed systems.

For production deployments:

1. **Enable Elasticsearch Security**: Change `xpack.security.enabled: false` to `true` in `install/roles/elasticsearch/templates/elasticsearch.yml.j2` (keep `xpack.security.http.ssl.enabled: false` so ES does not auto-configure TLS on the HTTP layer, which the playbook's localhost checks do not support), and set `install_elasticsearch_xpack: true` in `install/group_vars/all.yml` so the logstash role authenticates to Elasticsearch:
   ```yaml
   xpack.security.enabled: true
   xpack.security.http.ssl.enabled: false
   ```
2. **Configure TLS**: Set up SSL certificates for client-facing access (nginx/apache reverse proxy). Keep `xpack.security.http.ssl.enabled: false` for the Elasticsearch HTTP layer; the playbook's localhost checks and index-template load use plain HTTP.
3. **Set Strong Passwords**: Update `kibana_user`/`kibana_password`, and set `xpack_elastic_user_password` in `install/group_vars/all.yml` to the elastic password from step 4.
4. **Set the elastic password**: Package installs do not print the auto-generated password at startup, so after the first start run `/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic`, put the output in `xpack_elastic_user_password` (step 3), and re-run the playbook.
5. **Enable Firewall Rules**: Ensure `manage_firewall: true` in `group_vars/all.yml`
6. **Restrict ES Network Access**: Set `es_listen_external: false` (default) to limit ES to localhost

See the [Elasticsearch Security Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html) for detailed configuration.

## Migration from 6.x to 9.x

> [!CAUTION]
> **Direct upgrade from 6.x to 9.x is NOT supported by Elasticsearch.**
> You must perform a stepped upgrade: 6.x → 7.17.x → 8.x → 9.x, reindexing data at each major version.

If you are currently running ELK 6.x or earlier:

1. **Backup your data** using snapshots
2. Review [Elasticsearch breaking changes documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes.html)
3. Plan a stepped migration through intermediate versions
4. Test thoroughly in a non-production environment first

### Key Breaking Changes in ES 9.x

- Discovery settings changed: `discovery.zen.*` → `discovery.seed_hosts` and `cluster.initial_master_nodes`
- Security features (formerly X-Pack plugins) are now built-in and free
- Legacy per-component X-Pack install variables (`install_kibana_xpack`, `install_logstash_xpack`) are removed; set `install_elasticsearch_xpack: true` only when ES security is enabled
- Legacy index templates deprecated in favor of composable templates
- Removal of mapping types (no `_doc` type references)
- Stricter security and TLS requirements

## ELK/EFK Server Instructions

- Clone repo and setup your hosts file

```
git clone https://github.com/sadsfae/ansible-elk
cd ansible-elk
sed -i 's/host-01/elkserver/' hosts
sed -i 's/host-02/elkclient/' hosts
```

- If you're using a non-root user for Ansible, e.g. AWS EC2 likes to use ec2-user then set the follow below, default is root.

```
ansible_system_user: ec2-user
```

- Run the playbook

```
ansible-playbook -i hosts install/elk.yml
```

- (see playbook messages for completion status and next steps)
- Navigate to Kibana:
  - **Nginx (default)**: http://host-01:80
  - **Apache**: http://host-01/kibana
- **Login with nginx/apache HTTP Basic Auth** (not Elasticsearch credentials):
  - Username: `admin`
  - Password: `admin`
  - *Note*: This is the nginx/apache htpasswd authentication, not Elasticsearch. ES security is disabled by default for dev/test.

### Create your Kibana Index Pattern

- Next you'll login to your Kibana instance and create a Kibana index pattern.

![ELK](/image/elk6-0.png?raw=true "Click Explore on my Own")

- Note: Sample data can be useful, you can try it later however.

![ELK](/image/elk6-1.png?raw=true "Click Discover")

![ELK](/image/elk6-2.png?raw=true "Create index pattern")

![ELK](/image/elk6-3.png?raw=true "Select @timestamp from the drop-down and create index pattern")

![ELK](/image/elk6-4.png?raw=true "Click Discover")

- At this point you can setup your client(s) to start sending data via Filebeat/SSL

## ELK Client Instructions

- Run the client playbook against the generated `elk_server` variable

```
ansible-playbook -i hosts install/elk_client.yml --extra-vars 'elk_server=X.X.X.X'
```

- Once this completes return to your ELK and you'll see log results come in from ELK/EFK clients via filebeat

![ELK](/image/elk6-5.png?raw=true "watch the magic")

## Legacy ELK Versions

### Elasticsearch 6.x (RHEL7 Compatible)

The `6.8` branch provides Elasticsearch 6.x support with RHEL7/CentOS7 compatibility. This is the recommended branch for systems that cannot upgrade to RHEL8+.

### Elasticsearch 5.6 (Legacy)

The `5.6` branch provides Elasticsearch 5.x support for older deployments. See the branch compatibility table at the top of this README.

### Elasticsearch 2.4 (Legacy)

The `2.4` branch provides Elasticsearch 2.x support for very old or resource-constrained systems. See the branch compatibility table at the top of this README.

### Video Tutorial

- You can view a deployment video here (note: uses older ELK version):

[![Ansible Elk](http://img.youtube.com/vi/6is6Ecxc2zE/0.jpg)](http://www.youtube.com/watch?v=6is6Ecxc2zE "Deploying ELK with Ansible")

## File Hierarchy

```
.
├── hosts
├── install
│   ├── elk_client.yml
│   ├── elk.yml
│   ├── group_vars
│   │   └── all.yml
│   └── roles
│       ├── apache
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── 8080vhost.conf.j2
│       │       └── kibana.conf.j2
│       ├── curator
│       │   ├── files
│       │   │   └── curator.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── curator-action.yml.j2
│       │       └── curator-config.yml.j2
│       ├── elasticsearch
│       │   ├── files
│       │   │   ├── elasticsearch.in.sh
│       │   │   └── elasticsearch.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── elasticsearch.yml.j2
│       ├── elk_client
│       │   ├── files
│       │   │   └── elk.repo
│       │   ├── handlers
│       │   │   └── main.yml
│       │   └── tasks
│       │       └── main.yml
│       ├── filebeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── filebeat.yml.j2
│       │       └── rsyslog-openstack.conf.j2
│       ├── firewall
│       │   ├── handlers
│       │   │   └── main.yml
│       │   └── tasks
│       │       └── main.yml
│       ├── fluentd
│       │   ├── files
│       │   │   ├── filebeat-index-template.json
│       │   │   └── fluentd.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── fluentd.conf.j2
│       │       └── openssl_extras.cnf.j2
│       ├── heartbeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── heartbeat.yml.j2
│       ├── instructions
│       │   └── tasks
│       │       └── main.yml
│       ├── kibana
│       │   ├── files
│       │   │   └── kibana.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── kibana.yml.j2
│       │       └── openssl_extras.cnf.j2
│       ├── logstash
│       │   ├── files
│       │   │   ├── filebeat-index-template.json
│       │   │   ├── logstash.repo
│       │   │   └── logstash.service
│       │   ├── handlers
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   ├── ipv6-grub-disable.yml
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── 02-beats-input.conf.j2
│       │       ├── logstash.conf.j2
│       │       └── openssl_extras.cnf.j2
│       ├── metricbeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── metricbeat.yml.j2
│       ├── nginx
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── kibana.conf.j2
│       │       └── nginx.conf.j2
│       └── packetbeat
│           ├── meta
│           │   └── main.yml
│           ├── tasks
│           │   └── main.yml
│           └── templates
│               └── packetbeat.yml.j2
├── LICENSE
├── meta
│   └── main.yml
├── README.md
└── tests
    └── test-requirements.txt

58 directories, 62 files
```
