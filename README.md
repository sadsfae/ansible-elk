ansible-elk
===========
Ansible Playbook for setting up the ELK/EFK Stack and Filebeat client on remote hosts

![ELK](/image/ansible-elk.png?raw=true)

## What does it do?
   - Automated deployment of a full ELK or EFK stack (Elasticsearch, Logstash/Fluentd, Kibana)
     * 5.5+ and 2.4 ELK versions are maintained.
     * Uses Nginx as a reverse proxy for Kibana
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
   - RHEL7 or CentOS7+ server/client with no modifications
   - ELK/EFK server with at least 8G of memory (you can try with less but 5.x series is quite demanding - try 2.4 series if you have scarce resources).
     - Fedora 23 or higher needs to have ```yum python2 python2-dnf libselinux-python``` packages.
       * You can run this against Fedora clients prior to running Ansible ELK:
       - ```ansible fedora-client-01 -u root -m shell -i hosts -a "dnf install yum python2 libsemanage-python python2-dnf -y"```
   - You may want to modify ```vm.swappiness``` as ELK/EFK is demanding and swapping kills the responsiveness.
     - I am leaving this up to your judgement.
```
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p
```

## Notes
   - Current ELK version is 5.6.x but you can checkout the 2.4 branch if you want that series
   - Sets the nginx htpasswd to admin/admin initially
   - nginx ports default to 80/8080 for Kibana and SSL cert retrieval (configurable)
   - Uses OpenJDK for Java
   - It's fairly quick, takes around 3minutes on test VM
   - Filebeat templating is focused around OpenStack service logs
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
   - Navigate to the ELK at http://host-01:80
   - Default login is:
      - username: ```admin```
      - password: ```admin```

![ELK](/image/elk-index-5.x-1.png?raw=true "Select @timestamp from drop-down.")

![ELK](/image/elk-index-5.x-2.png?raw=true "Click the blue create button.")

![ELK](/image/elk-index-5.x-3.png?raw=true "Click Discover")

## ELK Client Instructions
   - Run the client playbook against the generated ``elk_server`` variable
```
ansible-playbook -i hosts install/elk-client.yml --extra-vars 'elk_server=X.X.X.X'
```
   - Once this completes return to your ELK and you'll see log results come in from ELK/EFK clients via filebeat
![ELK](/image/elk-index-5.x-4.png?raw=true "watch the magic")

## 2.4 ELK/EFK (Deprecated)
   - The 2.4 series of ELK/EFK is also available, to use this just clone the 2.4 branch
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
├── ansible-elk-6.2-wip
│   ├── ansible-elk-6.2-wip
│   ├── hosts
│   ├── install
│   │   ├── elk-client.yml
│   │   ├── elk.retry
│   │   ├── elk.yml
│   │   ├── group_vars
│   │   │   └── all.yml
│   │   └── roles
│   │       ├── curator
│   │       │   ├── files
│   │       │   │   └── curator.repo
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       ├── curator-action.yml.j2
│   │       │       └── curator-config.yml.j2
│   │       ├── elasticsearch
│   │       │   ├── files
│   │       │   │   ├── elasticsearch.in.sh
│   │       │   │   └── elasticsearch.repo
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       └── elasticsearch.yml.j2
│   │       ├── elk_client
│   │       │   ├── files
│   │       │   │   └── elk.repo
│   │       │   └── tasks
│   │       │       └── main.yml
│   │       ├── filebeat
│   │       │   ├── meta
│   │       │   │   └── main.yml
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       ├── filebeat.yml.j2
│   │       │       └── rsyslog-openstack.conf.j2
│   │       ├── firewall
│   │       │   └── tasks
│   │       │       └── main.yml
│   │       ├── fluentd
│   │       │   ├── files
│   │       │   │   ├── filebeat-index-template.json
│   │       │   │   └── fluentd.repo
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       ├── openssl_extras.cnf.j2
│   │       │       └── td-agent.conf.j2
│   │       ├── heartbeat
│   │       │   ├── meta
│   │       │   │   └── main.yml
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       └── heartbeat.yml.j2
│   │       ├── instructions
│   │       │   └── tasks
│   │       │       └── main.yml
│   │       ├── kibana
│   │       │   ├── files
│   │       │   │   ├── filebeat-dashboards.zip
│   │       │   │   ├── kibana.repo
│   │       │   │   └── logstash.repo
│   │       │   └── tasks
│   │       │       └── main.yml
│   │       ├── logstash
│   │       │   ├── files
│   │       │   │   ├── filebeat-index-template.json
│   │       │   │   └── logstash.repo
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       ├── 02-beats-input.conf.j2
│   │       │       ├── logstash.conf.j2
│   │       │       └── openssl_extras.cnf.j2
│   │       ├── metricbeat
│   │       │   ├── meta
│   │       │   │   └── main.yml
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       └── metricbeat.yml.j2
│   │       ├── nginx
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       ├── kibana.conf.j2
│   │       │       └── nginx.conf.j2
│   │       ├── packetbeat
│   │       │   ├── meta
│   │       │   │   └── main.yml
│   │       │   ├── tasks
│   │       │   │   └── main.yml
│   │       │   └── templates
│   │       │       └── packetbeat.yml.j2
│   │       └── xpack
│   │           └── tasks
│   │               └── main.yml
│   └── meta
│       └── main.yml
├── ansible-elk-6.2-wip.tar
├── hosts
├── install
│   ├── elk-client.yml
│   ├── elk.yml
│   ├── group_vars
│   │   └── all.yml
│   └── roles
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
│       │   │   ├── filebeat-dashboards.zip
│       │   │   ├── kibana.repo
│       │   │   └── logstash.repo
│       │   └── tasks
│       │       └── main.yml
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

105 directories, 101 files

```
