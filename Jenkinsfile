pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "product-catalog-backend:v1"
        FRONTEND_IMAGE = "product-catalog-frontend:v1"
        K8S_DIR = "kubernetes/k8s/overlays/dev"
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
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t $BACKEND_IMAGE ./backend
                    docker build -t $FRONTEND_IMAGE ./frontend
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image --severity CRITICAL,HIGH --exit-code 1 $BACKEND_IMAGE
                    trivy image --severity CRITICAL,HIGH --exit-code 1 $FRONTEND_IMAGE
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl apply -k $K8S_DIR
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/api --timeout=120s
                    kubectl rollout status deployment/web --timeout=120s
                    kubectl rollout status deployment/postgres --timeout=120s

                    kubectl get pods -o wide
                    kubectl get svc
                '''
            }
        }

        stage('API Health Check') {
            steps {
                sh '''
                    kubectl port-forward svc/api 8085:80 >/dev/null 2>&1 &
                    sleep 5
                    curl -sf http://localhost:8085/api/health
                '''
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD pipeline completed successfully"
        }

        failure {
            echo "❌ Pipeline failed"
        }

        always {
            echo "Pipeline finished"
        }
    }
}
