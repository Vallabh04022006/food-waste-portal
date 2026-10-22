
pipeline {
    agent any

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
                        bat 'docker build -t food-waste-portal:latest .'
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
    }
}
