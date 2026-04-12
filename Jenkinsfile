pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "pavankumargit/react-app"
        // IP address comes from Terraform output
        DEPLOY_SERVER = "ubuntu@13.201.2.198" 
    }

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    // sh 'docker build --build-arg REACT_APP_TMDB_API_KEY=your_actual_api_key_here -t pavankumargit/react-app:latest .'
                    sh 'docker build -t $DOCKER_IMAGE:latest .'
                }
            }
        }


        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    
                    // FIXED LINE: We use "SYSTEM" instead of "%USERNAME%"
                    // This works because Jenkins is running as the System Service
                    // bat 'icacls "%SSH_KEY%" /inheritance:r /grant:r SYSTEM:F'
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