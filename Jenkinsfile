pipeline {
    agent any
    
    environment {
        DOCKER_HUB_REPO = 'lasmor2025/demo-app'
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-credentials')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/lasmor2/helm-argon-cd.git'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    sh "docker build -t ${DOCKER_HUB_REPO}:v${buildNumber} ."
                    sh "docker tag ${DOCKER_HUB_REPO}:v${buildNumber} ${DOCKER_HUB_REPO}:latest"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    sh "echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin"
                    sh "docker push ${DOCKER_HUB_REPO}:v${buildNumber}"
                    sh "docker push ${DOCKER_HUB_REPO}:latest"
                }
            }
        }
        
        stage('Update Helm Values') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    sh "sed -i 's/tag: .*/tag: v${buildNumber}/' app-demo/value.yml"
                    sh "git add app-demo/value.yml"
                    sh "git commit -m 'Update image tag to v${buildNumber}'"
                    sh "git push origin main"
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
        }
    }
}