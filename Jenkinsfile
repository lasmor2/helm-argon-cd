pipeline {
    agent any
    
    environment {
        DOCKER_HUB_REPO = 'lasmor2025/demo-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/lasmor2/helm-argon-cd.git'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    bat "docker build -t ${DOCKER_HUB_REPO}:v${buildNumber} ."
                    bat "docker tag ${DOCKER_HUB_REPO}:v${buildNumber} ${DOCKER_HUB_REPO}:latest"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    bat "docker push ${DOCKER_HUB_REPO}:v${buildNumber}"
                    bat "docker push ${DOCKER_HUB_REPO}:latest"
                }
            }
        }
        
        stage('Update Helm Values') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    bat "powershell -Command \"(Get-Content app-demo/value.yml) -replace 'tag: .*', 'tag: v${buildNumber}' | Set-Content app-demo/value.yml\""
                    bat "git add app-demo/value.yml"
                    bat "git commit -m \"Update image tag to v${buildNumber}\""
                    bat "git push origin main"
                }
            }
        }
    }
    
    post {
        always {
            bat 'docker logout'
        }
    }
}