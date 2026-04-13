pipeline {
    agent any

    triggers {
        pollSCM('* * * * *')
    }

    environment {
        // DOCKER_IMAGE  = "abhishek327507/react-app"
        DEPLOY_SERVER = "ubuntu@13.201.2.198"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker logout || true'
                sh 'docker build -t $DOCKER_IMAGE:latest .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'docker logout || true'
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker push $DOCKER_IMAGE:latest'
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh 'chmod 600 "$SSH_KEY"'
                    sh """
                        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" $DEPLOY_SERVER '
                            sudo docker pull ${DOCKER_IMAGE}:latest
                            sudo docker stop react-app || true
                            sudo docker rm react-app || true
                            sudo docker run -d -p 80:80 --name react-app ${DOCKER_IMAGE}:latest
                        '
                    """
                }
            }
        }
    }
}