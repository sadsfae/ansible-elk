ansible-elk
===========
Ansible Playbook for setting up the ELK Stack

**What does it do?**
   - Automated deployment of a full ELK stack (elasticsearch, logstash, kibana)
     * Uses nginx as a reverse proxy
     * Generates SSL certificates for filebeat or logstash-forwarder
     * Adds either iptables or firewalld rules if firewall is active
     * Tunes elasticsearch heapsize to half your memory
     * It's fairly quick, takes around 3minutes on my local VM
 
**Requirements**
   - RHEL7, CentOS or Fedora Linux server
   - Ansible 1.8.x+

**Instructions**
   - Clone repo and setup your hosts file
```
git clone https://github.com/sadsfae/ansible-elk
cd ansible-elk
sed -i 's/host-01/yourhost/' hosts
```
   - Run the playbook
```
ansible-playbook -i hosts install/elk.yml
```
   - Navigate to the Server at http://yourhost

**To Do**
   - Write a client playbook for filebeat to send logs to the service

```
├── hosts
└── install
    ├── elk.yml
    ├── group_vars
    │   └── all
    └── roles
        ├── elasticsearch
        │   ├── files
        │   │   ├── elasticsearch.in.sh
        │   │   ├── elasticsearch.repo
        │   │   └── elasticsearch.yml
        │   └── tasks
        │       └── main.yml
        ├── kibana
        │   ├── files
        │   │   ├── kibana.repo
        │   │   └── logstash.repo
        │   └── tasks
        │       └── main.yml
        ├── logstash
        │   ├── files
        │   │   ├── 01-lumberjack-input.conf
        │   │   ├── 10-syslog.conf
        │   │   ├── 30-lumberjack-output.conf
        │   │   └── logstash.repo
        │   └── tasks
        │       └── main.yml
        └── nginx
            ├── files
            │   └── nginx.conf
            ├── main.yml
            ├── tasks
            │   └── main.yml
            └── templates
                └── kibana.conf.j2
```
