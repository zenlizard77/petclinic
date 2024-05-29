 # Overview:

This proof-of-concept project uses a Jenkins pipeline to build, test, create a container, and upload the Spring Boot Pet Clinic Application to Artifactory for easy use.

## Quick Start:

You can quickly test the application via Docker or Kubernetes.

For Docker:
```
docker run -d --name clinic -p 8080:8080 goodner.jfrog.io/petclinic-docker/pet-clinicapp:latest
```
It can be accessed via http://localhost:8080 once running

For Kubernetes via kubectl:

```
kubectl create ns petclinic
kubectl apply -f petclinic.yaml -n petclinic
```
You might need to edit the petclinic.yaml file if you want to change to clusterIP from LoadBalancer.

## Preparing Jenkins

Before running our pipeline we will need to configure Jenkins to have all neccessary plugins, tools, and credentials ready to go

### Plugins:
For all the tools we will be using in the pipeline we will need to enable the following additional plugins:
```
Git Plugin
JFrog Plugin
Eclipse Temurin installer Plugin
Docker (API, Commons, and Pipeline)
```
The plugin section is found under the Manage Jenkins Menu.

### Tools:
Additionally under Manage Jenkins --> Tools make sure to configure the Maven, JDK, Docker, Git, and JFrog sections to install automatically or are configured as you wish.

### Credentials:
The following credentials need to be added to Jenkins:
```
Artifactory
DockerHub
JFrog
```
## Pipeline

Once things are ready in Jenkins you can deploy a PipeLine using the pipeline script found below or from the file Petclinic-JenkinsPOC.pipeline. It contains the steps to download, compile, test, build the container, scan, and upload the image into Artifactory. I have also included the output from a successful run in the petclinic-pipeline.output file.

```
pipeline {
    agent any 
    
    tools{
        jdk 'JDK'
        maven 'Maven3'
        jfrog 'jfrog-cli'
    }
    
    stages{
        
        stage("Git Checkout"){
            steps{
                //I needed to add credentials to pull from a popular project. In production I would git clone this and work from that repo. 
                //I didn't here as I wasn't sure if it will be human or programmatically checked so I stuck with the technical assessments ask
                git branch: 'main', changelog: false, poll: false, credentialsId: 'c886c049-cb5a-4187-abf9-2764b3e7b48a', url: 'https://github.com/spring-projects/spring-petclinic'
            }
        }
        
        stage("Compile"){
            steps{
                sh "mvn clean compile"
            }
        }
        
         stage("Maven Testing"){
            steps{
                sh "mvn test"
            }
        }
        
         stage("Build"){
            steps{
                sh "mvn clean install"
            }
        }
        
         stage("Container Build using Maven"){
            steps{
                sh "mvn spring-boot:build-image"
            }
        }
        
        stage("Docker Rename/Tag - Change to latest and target Artifactory"){
            steps{
                script{
                        withDockerRegistry(credentialsId: 'dockercreds', toolName: 'docker') {
                             //Get the version information from Maven to retag
                             def version = sh script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true
                             //Tag build for to proper repo
                             sh "docker tag spring-petclinic:${version} goodner.jfrog.io/petclinic-docker/pet-clinicapp:latest"
                    }
                }
            }
        }
        
        stage('Scan and push image to Artifactory') {
			steps {
				dir('docker-oci-examples/docker-example/') {
					// Scan Docker image for vulnerabilities
					jf 'docker scan goodner.jfrog.io/petclinic-docker/pet-clinicapp:latest'
					// Push image to Artifactory
					jf 'docker push goodner.jfrog.io/petclinic-docker/pet-clinicapp:latest'
					
				}
			}
		}
        
     }
}
```
