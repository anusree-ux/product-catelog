pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "product-catalog-backend:v1"
        FRONTEND_IMAGE = "product-catalog-frontend:v1"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh 'docker --version'
                sh 'kubectl version --client'
                sh 'helm version'
                sh 'trivy --version'
                sh 'git --version'
            }
        }

    }

    post {
        always {
            echo 'Pipeline finished.'
        }

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed.'
        }
    }
}
