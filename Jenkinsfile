pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    environment {
        DOCKER_HUB_REPO = 'lasmor2025/demo-app'
        DOCKER_HUB_CREDENTIALS = credentials('dockerhub-credentials')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        GIT_BRANCH = 'main'
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
                    bat "docker build -t %DOCKER_HUB_REPO%:v${buildNumber} ."
                    bat "docker tag %DOCKER_HUB_REPO%:v${buildNumber} %DOCKER_HUB_REPO%:latest"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    bat "echo %DOCKER_HUB_CREDENTIALS_PSW% | docker login -u %DOCKER_HUB_CREDENTIALS_USR% --password-stdin"
                    bat "docker push %DOCKER_HUB_REPO%:v${buildNumber}"
                    bat "docker push %DOCKER_HUB_REPO%:latest"
                }
            }
        }
        
        stage('Update Helm Values') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER
                    // Windows sed alternative using PowerShell
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
