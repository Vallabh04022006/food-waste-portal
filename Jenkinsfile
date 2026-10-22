
pipeline {
    agent any

    environment {
        IMAGE = 'vallabh04022006/food-waste-portal'
        DEPLOYMENT = 'food-waste-deployment'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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
                archiveArtifacts(
                    artifacts: 'index.html,Dockerfile,deployment.yaml',
                    fingerprint: true
                )
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
                    @echo off
                    powershell -NoProfile -Command "$env:DOCKER_TOKEN | docker login -u $env:DOCKER_USER --password-stdin; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"
                    if errorlevel 1 exit /b 1

                    docker push %IMAGE%:%BUILD_NUMBER%
                    if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG'
                    )
                ]) {
                    bat '''
                    kubectl set image deployment/%DEPLOYMENT% food-waste=%IMAGE%:%BUILD_NUMBER%
                    '''
                }
            }
        }

        stage('Verify Rollout') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG'
                    )
                ]) {
                    script {
                        int result = bat(
                            script: 'kubectl rollout status deployment/%DEPLOYMENT% --timeout=90s',
                            returnStatus: true
                        )

                        if (result != 0) {

                            echo '======================================'
                            echo 'FAULTY DEPLOYMENT DETECTED!'
                            echo 'STARTING AUTOMATIC ROLLBACK...'
                            echo '======================================'

                            bat 'kubectl rollout undo deployment/%DEPLOYMENT%'

                            int rollbackResult = bat(
                                script: 'kubectl rollout status deployment/%DEPLOYMENT% --timeout=90s',
                                returnStatus: true
                            )

                            if (rollbackResult == 0) {

                                echo '======================================'
                                echo 'ROLLBACK SUCCESSFUL!'
                                echo 'PREVIOUS DEPLOYMENT RESTORED!'
                                echo '======================================'

                                bat 'kubectl get deployment %DEPLOYMENT%'
                                bat 'kubectl get pods'

                                currentBuild.description = 'Automatic rollback successful'

                            } else {
                                error('ROLLBACK FAILED! Check Kubernetes.')
                            }

                        } else {

                            echo '======================================'
                            echo 'DEPLOYMENT SUCCESSFUL!'
                            echo 'APPLICATION IS RUNNING!'
                            echo '======================================'

                        }
                    }
                }
            }
        }
    }
}
