pipeline {
    agent any

    environment {
        // Nombre de la imagen Docker
        IMAGE_NAME = 'cristobalobos/backend-nest'
        
        // Docker Hub
        DOCKER_HUB_REGISTRY = 'docker.io'
        DOCKER_HUB_CREDENTIALS = 'docker-hub-credentials'
        
        // GitHub Packages
        GITHUB_REGISTRY = 'ghcr.io'
        GITHUB_USERNAME = 'cristobalobos'
        GITHUB_IMAGE_NAME = "${GITHUB_REGISTRY}/${GITHUB_USERNAME}/backend-nest"
        GITHUB_TOKEN_CREDENTIALS = 'github-token-credentials'
        
        // Kubernetes
        K8S_NAMESPACE = 'clobos'
        K8S_DEPLOYMENT = 'backend-nest'
        KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    echo '📦 Instalando dependencias...'
                    sh 'npm ci'
                    echo '✅ Dependencias instaladas correctamente'
                }
            }
        }

        stage('Testing') {
            steps {
                script {
                    echo '🧪 Ejecutando tests...'
                    sh 'npm test'
                    echo '✅ Tests completados exitosamente'
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    echo '🔨 Compilando aplicación...'
                    sh 'npm run build'
                    echo '✅ Build completado exitosamente'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo '🐳 Construyendo imagen Docker...'
                    def imageTag = "${IMAGE_NAME}:${BUILD_NUMBER}"
                    def imageTagLatest = "${IMAGE_NAME}:latest"
                    
                    sh """
                        docker build -t ${imageTag} .
                        docker tag ${imageTag} ${imageTagLatest}
                    """
                    
                    echo "✅ Imagen construida: ${imageTag} y ${imageTagLatest}"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo '📤 Subiendo imagen a Docker Hub...'
                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_HUB_CREDENTIALS}",
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh """
                            echo \$DOCKER_PASSWORD | docker login ${DOCKER_HUB_REGISTRY} -u \$DOCKER_USERNAME --password-stdin
                            
                            docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${IMAGE_NAME}:latest
                            
                            docker logout ${DOCKER_HUB_REGISTRY}
                        """
                    }
                    echo "✅ Imagen subida a Docker Hub con tags: ${BUILD_NUMBER} y latest"
                }
            }
        }

        stage('Push to GitHub Packages') {
            steps {
                script {
                    echo '📤 Subiendo imagen a GitHub Packages...'
                    withCredentials([string(
                        credentialsId: "${GITHUB_TOKEN_CREDENTIALS}",
                        variable: 'GITHUB_TOKEN'
                    )]) {
                        sh """
                            echo \$GITHUB_TOKEN | docker login ${GITHUB_REGISTRY} -u ${GITHUB_USERNAME} --password-stdin
                            
                            docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${GITHUB_IMAGE_NAME}:${BUILD_NUMBER}
                            docker tag ${IMAGE_NAME}:latest ${GITHUB_IMAGE_NAME}:latest
                            
                            docker push ${GITHUB_IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${GITHUB_IMAGE_NAME}:latest
                            
                            docker logout ${GITHUB_REGISTRY}
                        """
                    }
                    echo "✅ Imagen subida a GitHub Packages con tags: ${BUILD_NUMBER} y latest"
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                script {
                    echo '🚀 Actualizando deployment en Kubernetes...'
                    withCredentials([file(
                        credentialsId: "${KUBECONFIG_CREDENTIALS}",
                        variable: 'KUBECONFIG_FILE'
                    )]) {
                        sh """
                            export KUBECONFIG=\${KUBECONFIG_FILE}
                            
                            # Actualizar la imagen del deployment con el build number
                            kubectl set image deployment/${K8S_DEPLOYMENT} \
                                backend-nest=${GITHUB_IMAGE_NAME}:${BUILD_NUMBER} \
                                -n ${K8S_NAMESPACE}
                            
                            # Verificar el rollout
                            kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=5m
                            
                            # Mostrar estado de los pods
                            kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT}
                        """
                    }
                    echo "✅ Deployment actualizado con imagen: ${GITHUB_IMAGE_NAME}:${BUILD_NUMBER}"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completado exitosamente'
        }
        failure {
            echo '❌ Pipeline falló'
        }
        always {
            echo '🧹 Limpiando...'
            sh 'docker system prune -f || true'
        }
    }
}

