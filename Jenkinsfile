
pipeline {
    agent any

    environment {
        IMAGE = 'vallabh04022006/food-waste-portal'
        DEPLOYMENT = 'food-waste-deployment'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/vallabh04022006/food-waste-portal.git'
            }
        }

        stage('Parallel Build and Test') {
            parallel {
                stage('Build') {
                    steps {
                        bat 'docker build -t %IMAGE%:%BUILD_NUMBER% .'
                    }
                }

                stage('Test') {
                    steps {
                        bat 'findstr /C:"Food Waste Tracking Portal" index.html'
                        bat 'findstr /C:"Redistribution Status Dashboard" index.html'
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'index.html,Dockerfile,deployment.yaml',
                                 fingerprint: true
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )
                ]) {
                    bat '''
                    echo %DOCKER_TOKEN% | docker login -u %DOCKER_USER% --password-stdin
                    docker push %IMAGE%:%BUILD_NUMBER%
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(credentialsId: 'kubeconfig',
                         variable: 'KUBECONFIG')
                ]) {
                    bat '''
                    kubectl apply -f deployment.yaml
                    kubectl set image deployment/%DEPLOYMENT% food-waste=%IMAGE%:%BUILD_NUMBER%
                    '''
                }
            }
        }

        stage('Verify Rollout') {
            steps {
                withCredentials([
                    file(credentialsId: 'kubeconfig',
                         variable: 'KUBECONFIG')
                ]) {
                    script {
                        int result = bat(
                            script: 'kubectl rollout status deployment/%DEPLOYMENT% --timeout=90s',
                            returnStatus: true
                        )

                        if (result != 0) {
                            bat 'kubectl rollout undo deployment/%DEPLOYMENT%'
                            bat 'kubectl rollout status deployment/%DEPLOYMENT% --timeout=90s'
                            error('Rollout failed. Previous release restored.')
                        }
                    }
                }
            }
        }
    }
}
