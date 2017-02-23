ansible-elk
===========
Ansible Playbook for setting up the ELK/EFK Stack and Filebeat client on remote hosts

![ELK](/image/ansible-elk.png?raw=true)

**What does it do?**
   - Automated deployment of a full ELK or EFK stack (Elasticsearch, Logstash/Fluentd, Kibana)
     * 5.2 and 2.4 ELK versions are maintained.
     * Uses Nginx as a reverse proxy for Kibana
     * Generates SSL certificates for Filebeat or Logstash-forwarder
     * Adds either iptables or firewalld rules if firewall is active
     * Tunes Elasticsearch heapsize to half your memory, to a max of 32G
     * Deploys ELK clients using SSL and Filebeat for Logstash (Default)
     * Deploys rsyslog if Fluentd is chosen over Logstash, picks up
       the same set of OpenStack-related logs in /var/log/*
     * All service ports can be modified in ```install/group_vars/all.yml```
     * Optionally install [curator](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/index.html)
     * This is also available on [Ansible Galaxy](https://galaxy.ansible.com/sadsfae/ansible-elk/)

**Requirements**
   - RHEL7 or CentOS7+ server/client with no modifications
     - Fedora 23 or higher needs to have ```yum python2 python2-dnf libselinux-python``` packages.
       * You can run this against Fedora clients prior to running Ansible ELK:
       - ```ansible fedora-client-01 -u root -m shell -i hosts -a "dnf install yum python2 libsemanage-python python2-dnf -y"```
   - Deployment tested on Ansible 1.9.4 and 2.0.2

**Notes**
   - Current ELK version is 5.2.1 but you can checkout the 2.4 branch if you want that series
   - Sets the nginx htpasswd to admin/admin initially
   - nginx ports default to 80/8080 for Kibana and SSL cert retrieval (configurable)
   - Uses OpenJDK for Java
   - It's fairly quick, takes around 3minutes on test VM
   - Filebeat templating is focused around OpenStack service logs
   - Fluentd can be substituted for the default Logstash
     - Set ```logging_backend: fluentd``` in ```group_vars/all.yml```
   - Install curator by setting ```install_curator_tool: true``` in ```install/group_vars/all.yml```

**ELK Server Instructions**
   - Clone repo and setup your hosts file
```
git clone https://github.com/sadsfae/ansible-elk
cd ansible-elk
sed -i 's/host-01/elkserver/' hosts
sed -i 's/host-02/elkclient/' hosts
```
   - Run the playbook
```
ansible-playbook -i hosts install/elk.yml
```
   - Navigate to the server at http://yourhost
   - Default login is admin/admin
![ELK](/image/elk-index.png?raw=true "Click the green button.")

**ELK Client Instructions**
   - Run the client playbook against the generated ``elk_server`` variable
```
ansible-playbook -i hosts install/elk-client.yml --extra-vars 'elk_server=X.X.X.X'
```
   - You can view a deployment video here:


[![Ansible Elk](http://img.youtube.com/vi/6is6Ecxc2zE/0.jpg)](http://www.youtube.com/watch?v=6is6Ecxc2zE "Deploying ELK with Ansible")


**File Hierarchy**
```
.
├── hosts
└── install
    ├── elk-client.yml
    ├── elk.yml
    ├── group_vars
    │   └── all.yml
    └── roles
        ├── curator
        │   ├── files
        │   │   └── curator.repo
        │   └── tasks
        │       └── main.yml
        ├── elasticsearch
        │   ├── files
        │   │   ├── elasticsearch.in.sh
        │   │   └── elasticsearch.repo
        │   └── tasks
        │       └── main.yml
        ├── filebeat
        │   ├── files
        │   │   └── filebeat.repo
        │   ├── tasks
        │   │   └── main.yml
        │   └── templates
        │       ├── filebeat.yml.j2
        │       └── rsyslog-openstack.conf.j2
        ├── fluentd
        │   ├── files
        │   │   ├── filebeat-index-template.json
        │   │   └── fluentd.repo
        │   ├── tasks
        │   │   └── main.yml
        │   └── templates
        │       ├── openssl_extras.cnf.j2
        │       └── td-agent.conf.j2
        ├── kibana
        │   ├── files
        │   │   ├── filebeat-dashboards.zip
        │   │   ├── kibana.repo
        │   │   └── logstash.repo
        │   └── tasks
        │       └── main.yml
        ├── logstash
        │   ├── files
        │   │   ├── filebeat-index-template.json
        │   │   └── logstash.repo
        │   ├── tasks
        │   │   └── main.yml
        │   └── templates
        │       ├── 02-beats-input.conf.j2
        │       ├── logstash.conf.j2
        │       └── openssl_extras.cnf.j2
        └── nginx
            ├── tasks
            │   └── main.yml
            └── templates
                ├── kibana.conf.j2
                └── nginx.conf.j2

27 directories, 31 files
```
