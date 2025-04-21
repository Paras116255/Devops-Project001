Banking and finance Domain Project:
Paras Kumar
TOOLS:
-	GIT and Github -> Maintain source code
-	Terraform to create a EC2 instance
-	Ansible -> Setup to install required packages
-	Jenkins -> Create Build Pipeline and integrate webhooks/pollSCM
-	Docker -> Use docker to build images and push to dockerhub
-	Prometheous and Grafana  - monitor Jenkins pipeline


Step 1: 
Create a VM and install Terraform on it
=============================
OS: ubuntu 22
Instance_type: t2.micro
Add Network settings  add security group -> All traffic and anywhere

Connect to the instance.
Steps to install terraform:
=================================
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
 

Create Accesskey and secret key in AWS for terraform to connect:
Once Accesskey and secret key is created in AWS – IAM
Go and configure it on the terraform VM
 




Install awscli on the VM
# apt-get update
# apt-get install awscli -y
# aws configure
 

Give the valid access key
Give the valid secret key

Press enter, no need to give any region and format option
To verify if the credentials have been set for aws
# cat ~/.aws/credentials
Write terraform configuration file to create an EC2 server and install ansible on it.  
# mkdir myproject
# cd myproject
# vim main.tf



Terraform file (main.tf)
provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "paras-vpc" {
 cidr_block = "10.0.0.0/16"
  tags = {
   Name = "paras-vpc"
}
}

resource "aws_subnet" "subnet-1"{

vpc_id = aws_vpc.paras-vpc.id
cidr_block = "10.0.1.0/24"
depends_on = [aws_vpc.paras-vpc]
map_public_ip_on_launch = true
  tags = {
   Name = "paras-subnet"
}
}

resource "aws_route_table" "paras-route-table"{
vpc_id = aws_vpc.paras-vpc.id
  tags = {
   Name = "paras-route-table"
}
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.paras-route-table.id
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.paras-vpc.id
 depends_on = [aws_vpc.paras-vpc]
   tags = {
   Name = "paras-gw"
}
}

resource "aws_route" "paras-route" {

route_table_id = aws_route_table.paras-route-table.id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
}

variable "sg_ports" {
type = list(number)
default = [8080,80,22,443]
}
resource "aws_security_group" "paras-sg" {
  name        = "sg_rule"
  vpc_id = aws_vpc.paras-vpc.id
  dynamic  "ingress" {
    for_each = var.sg_ports
    iterator = port
    content{
    from_port        = port.value
    to_port          = port.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  }
egress {

    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

}
}

resource "aws_instance" "myec2" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.medium"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-main"
  }

}

resource "aws_instance" "myec2-test" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.micro"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-test"
  }

}

resource "aws_instance" "myec2-prod" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.micro"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-prod"
  }

}


# terraform init

# terraform apply --auto-approve

 




Step 2:

Install all the tools for CICD
Go the us-east-1 region:

Please connect to the newly created EC2 instance which has Ansible installed on it -> We can call this instance as Ansible Controller.
[make sure its instance type is t2.medium because we have to setup Jenkins, docker, monitoring tools on this]
Connect using EC2 instance connect
Check if ansible is installed:
# ansible --version
# sudo su –
Run the commands to install Ansible

  sudo apt update
  sudo apt install software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt install ansible -y
  
Run the below commands for installing Jenkins: [Always take the lastest steps for Jenkins]

 
Add Jenkins key to the server
    #  sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
Make Jenkins apt repo
    # echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# vim playbook1.yml
- name: Install and set up devops tools
  hosts: localhost
  become: true
  tasks:
    - name: update the apt repo
      command: apt-get update
    - name: Install multiple packages
      package: name={{item}} state=present
      loop:
        - git
        - docker.io
        - openjdk-17-jdk
    - name: install jenkins
      command: sudo apt-get install jenkins -y
    - name: start jenkins and docker service
      service: name={{item}} state=started
      loop:
        - jenkins
        - docker


# ansible-playbook playbook1.yml
Now Create user on all servers (main,test,PROD):
#sudo adduser ansiuser
#newpassword: ansiuser
#retype password: ansiuser



Step 3:
(IMP) Go to the /etc/sudoers on every server and edit it with:
#vim /etc/sudoers
ansiuser ALL=NOPASSWD: ALL

(IMP) Go to the /etc/ssh/sshd_config on every server and edit it with:
#vim /etc/ssh/sshd_config
(enable password authentication)
 

(imp) go to the main-dev server and generate the ssh key
#ssh-keygen –t rsa
Press enter again and again
#cat /home/ansiuser/.ssh/id_rsa.pub
 


(imp) paste these key to all the worker nodes
On Worker Nodes
#mkdir .ssh
# echo “<generated-key>” >>  ~/.ssh/authorized_keys
Now create myinventory file on Main-dev server
#vim myinventory


[webserver]
10.0.1.38
10.0.1.109

Save it

Now Create the ansible.cfg file
#vim ansible.cfg
[defaults]
inventory = /home/ansiuser/myinventory

save it

Now Create the playbook2.yml
- name: Install and set up devops tools
  hosts: webserver
  become: true
  tasks:
    - name: update the apt repo
      command: apt-get update
    - name: Install multiple packages
      package: name={{item}} state=present
      loop:
        - git
        - docker.io
        - openjdk-17-jdk
    - name: create the jenkins directory on the webserver
      file: path=/tmp/jenkinsdir satte=directory




#ansible-playbook playbook2.yml
 
All machines ansible are connected
Step 4: Containerize and implement microservice architecture
We will write a dockerfile and save it in the github repo

FROM openjdk:11
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app.jar"]

We will go to the CICD pipeline in Jenkins  add a stage to  build dockerfile in to an Image

We will run the image to deploy application on container.

Before running the pipeline, go to the terminal of VM and execute this command:
This command will allow Jenkins to run docker commands
# chmod -R 777 /var/run/docker.sock
 

Now On the Jenkins server after setup the maven 
-	Create a new item (CICDpipelin-project01)
-	Write the pipeline
-	And build the project
PIPELINE

pipeline{
    
    agent any
    
    tools{
        maven 'mymaven'
    }
    
    stages{
        stage('Clone Repo')
        {
            steps{
                git 'https://github.com/Paras116255/banking-finance-Project001.git'
            }
        }
        stage('Test Code')
        {
            steps{
                sh 'mvn test'
            }
        }
        
        stage('Build Code')
        {
            steps{
                sh 'mvn package'
            }
        }
        stage('Build Image')
        {
            steps{
                sh 'docker build -t myproject1:$BUILD_NUMBER .'
            }
        }
        
        stage('Deploy the Image')
        {
            steps{
                sh 'docker run -d -P myproject1:$BUILD_NUMBER '
            }
        }
    }
}

Now build the projects
 
 



Now Install the Prometheus on the Jenkins plugin and restart the jenkins
 
Now Install the Prometheus on the server (I user the terraform VM to use as a prometheus server)
To install follow these commands:
To install and configure Prometheus and Grafana as monitoring and visualization tools, you can follow the steps below:

Create a system user for Prometheus using below commnds:
sudo useradd --no-create-home --shell /bin/false prometheus

Create the directories in which we will be storing our configuration files and libraries:
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
Set the ownership of the /var/lib/prometheus directory with below command:
sudo chown prometheus:prometheus /var/lib/prometheus
You need to inside /tmp :
cd /tmp/
Go to official pgae downloads Prometheus:

https://prometheus.io/download/#prometheus


# wget https://github.com/prometheus/prometheus/releases/download/v3.0.0/prometheus-3.0.0.linux-amd64.tar.gz

# sudo tar -xvf prometheus-3.0.0.linux-amd64.tar.gz
Move the configuration file and set the owner to the prometheus
cd prometheus-3.0.0.linux-amd64
sudo mv promotool /etc/prometheus
sudo mv prometheus.yml /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus
Move the binaries and set the owner:
sudo mv prometheus /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
Create the service file using below command:
sudo nano /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target

Reload systemd:
sudo systemctl daemon-reload








Start and enable Prometheus service:
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
Now access Prometehus in your browser
http://3.111.47.169:9090/targets
 


Now add the node exporter to the test server just to check Prometheus is up and fetching the data correctly
Step #2:Install Node Exporter on Ubuntu 22.04 LTS
# wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
# sudo tar xvfz node_exporter-*.*-amd64.tar.gz

Move the binary file of node exporter to /usr/local/bin location.
sudo mv node_exporter-*.*-amd64/node_exporter /usr/local/bin/

Create a node_exporter user to run the node exporter service
sudo useradd -rs /bin/false node_exporter
Create a Custom Node Exporter Service
sudo nano /etc/systemd/system/node_exporter.service
[Unit]

Description=Node Exporter

After=network.target


[Service]

User=node_exporter

Group=node_exporter

Type=simple

ExecStart=/usr/local/bin/node_exporter

 

[Install]
WantedBy=multi-user.target
=======================
Reload the systemd
sudo systemctl daemon-reload

To Start, enable node exporter:
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
Lets update our configuration file on the installed Prometheus server using below command:







sudo vim /etc/prometheus/prometheus.yml
 
Save it
And check the connectivity
 







And do the same for Jenkins server
 
Save it and restart the Prometheus server
#systemctl restart prometheus
Check the Prometheus
 

Now Create a new ec2 server and install grafana
Install Grafana on Ubuntu 22.04 LTS
Download the Grafana GPG key with wget, then pipe the output to apt-key. This will add the key to your APT installation’s list of trusted keys, which will allow you to download and verify the GPG-signed Grafana package:
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
Next, add the Grafana repository to your APT sources:
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
Refresh your APT cache to update your package lists:
sudo apt update
You can now proceed with the installation:
sudo apt install grafana
Once Grafana is installed, use systemctl to start the Grafana server:
sudo systemctl start grafana-server
Next, verify that Grafana is running by checking the service’s status:
sudo systemctl status grafana-server
sudo systemctl enable grafana-server
Lets Access in browser:
http://15.207.54.137/:3000
 
Output:
default username: admin
default password: admin
Click Add data source and select Prometheus For the URL,
 enter http://3.111.47.169:9090/and click Save and test. 
You can see Data source is working.
Click on Save and Test.
Let’s add Dashboard for a better view in Grafana
Click On Dashboard → + symbol → Import Dashboard
Click on Import Dashboard paste this code 9964 and click on load


 
 

