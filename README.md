ansible-elk
===========
Ansible Playbook for setting up the ELK/EFK Stack and Filebeat client on remote hosts

![ELK](/image/ansible-elk.png?raw=true)

[![CI](https://travis-ci.org/sadsfae/ansible-elk.svg?branch=master)](https://travis-ci.org/sadsfae/ansible-elk)

## What does it do?
   - Automated deployment of a full 6.8+ ELK or EFK stack (Elasticsearch, Logstash/Fluentd, Kibana)
     * `5.6` and `2.4` ELK versions are maintained as branches and `master` branch will be 6.x currently.
     * Uses Nginx as a reverse proxy for Kibana, or optionally Apache via `apache_reverse_proxy: true`
     * Generates SSL certificates for Filebeat or Logstash-forwarder
     * Adds either iptables or firewalld rules if firewall is active
     * Tunes Elasticsearch heapsize to half your memory, to a max of 32G
     * Deploys ELK clients using SSL and Filebeat for Logstash (Default)
     * Deploys rsyslog if Fluentd is chosen over Logstash, picks up
       the same set of OpenStack-related logs in /var/log/*
     * All service ports can be modified in ```install/group_vars/all.yml```
     * Optionally install [curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html)
     * Optionally install [Elastic X-Pack Suite](https://www.elastic.co/guide/en/x-pack/current/xpack-introduction.html)
     * This is also available on [Ansible Galaxy](https://galaxy.ansible.com/sadsfae/ansible-elk/)

## Requirements
   - RHEL7 or CentOS7 server/client with no modifications
   - ELK/EFK server with at least 8G of memory (you can try with less but 5.x series is quite demanding - try 2.4 series if you have scarce resources).
   - You may want to modify ```vm.swappiness``` as ELK/EFK is demanding and swapping kills the responsiveness.
     - I am leaving this up to your judgement.
```
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p
```

## Notes
   - Current ELK version is 6.x but you can checkout the 5.6 or 2.4 branch if you want that series
   - Sets the nginx htpasswd to admin/admin initially
   - nginx ports default to 80/8080 for Kibana and SSL cert retrieval (configurable)
   - Uses OpenJDK for Java
   - It's fairly quick, takes around 3minutes on a test VM
   - Fluentd can be substituted for the default Logstash
     - Set ```logging_backend: fluentd``` in ```group_vars/all.yml```
   - Install curator by setting ```install_curator_tool: true``` in ```install/group_vars/all.yml```
   - Install [Elastic X-Pack Suite](https://www.elastic.co/guide/en/x-pack/current/xpack-introduction.html) for Elasticsearch, LogStash or Kibana via:
     - ```install_elasticsearch_xpack: true```
     - ```install_kibana_xpack: true```
     - ```install_logstash_xpack: true```
     - Note: Deploying X-Pack will wrap your ES with additional authentication and security, Kibana for example will have it's own credentials now - the default is username: ```elastic``` and password: ```changeme```

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
   - (see playbook messages)
   - Navigate to the ELK at http://host-01:80 (default, nginx) or http://host-01/kibana (apache)
   - Default login is:
      - username: ```admin```
      - password: ```admin```

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
   - Run the client playbook against the generated ``elk_server`` variable
```
ansible-playbook -i hosts install/elk-client.yml --extra-vars 'elk_server=X.X.X.X'
```
   - Once this completes return to your ELK and you'll see log results come in from ELK/EFK clients via filebeat

![ELK](/image/elk6-5.png?raw=true "watch the magic")

## 5.6 ELK/EFK (Deprecated)
   - The 5.6 series of ELK/EFK is also available, to use this just use the 5.6 branch
```
git clone https://github.com/sadsfae/ansible-elk
cd ansible-elk
git checkout 5.6
```
## 2.4 ELK/EFK (Deprecated)
   - The 2.4 series of ELK/EFK is also available, to use this just use the 2.4 branch
```
git clone https://github.com/sadsfae/ansible-elk
cd ansible-elk
git checkout 2.4
```
   - You can view a deployment video here:

[![Ansible Elk](http://img.youtube.com/vi/6is6Ecxc2zE/0.jpg)](http://www.youtube.com/watch?v=6is6Ecxc2zE "Deploying ELK with Ansible")


## File Hierarchy
```
.
├── hosts
├── install
│   ├── elk_client.yml
│   ├── elk.yml
│   ├── group_vars
│   │   └── all.yml
│   └── roles
│       ├── apache
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── 8080vhost.conf.j2
│       │       └── kibana.conf.j2
│       ├── curator
│       │   ├── files
│       │   │   └── curator.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── curator-action.yml.j2
│       │       └── curator-config.yml.j2
│       ├── elasticsearch
│       │   ├── files
│       │   │   ├── elasticsearch.in.sh
│       │   │   └── elasticsearch.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── elasticsearch.yml.j2
│       ├── elk_client
│       │   ├── files
│       │   │   └── elk.repo
│       │   └── tasks
│       │       └── main.yml
│       ├── filebeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── filebeat.yml.j2
│       │       └── rsyslog-openstack.conf.j2
│       ├── firewall
│       │   ├── handlers
│       │   │   └── main.yml
│       │   └── tasks
│       │       └── main.yml
│       ├── fluentd
│       │   ├── files
│       │   │   ├── filebeat-index-template.json
│       │   │   └── fluentd.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── openssl_extras.cnf.j2
│       │       └── td-agent.conf.j2
│       ├── heartbeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── heartbeat.yml.j2
│       ├── instructions
│       │   └── tasks
│       │       └── main.yml
│       ├── kibana
│       │   ├── files
│       │   │   └── kibana.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── kibana.yml.j2
│       ├── logstash
│       │   ├── files
│       │   │   ├── filebeat-index-template.json
│       │   │   └── logstash.repo
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── 02-beats-input.conf.j2
│       │       ├── logstash.conf.j2
│       │       └── openssl_extras.cnf.j2
│       ├── metricbeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── metricbeat.yml.j2
│       ├── nginx
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       ├── kibana.conf.j2
│       │       └── nginx.conf.j2
│       ├── packetbeat
│       │   ├── meta
│       │   │   └── main.yml
│       │   ├── tasks
│       │   │   └── main.yml
│       │   └── templates
│       │       └── packetbeat.yml.j2
│       └── xpack
│           └── tasks
│               └── main.yml
└── meta
    └── main.yml

56 directories, 52 files

```
