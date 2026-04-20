pipeline{
    agent any
    tools{
        jdk 'JDK17'
        nodejs 'node18'
    }
    environment{
        DOCKER_IMAGE = "tawfee421/uber"
        DOCKER_TAG = '${BUILD_NUMBER}'
        IMAGE = '$DOCKER_IMAGE:$DOCKER_TAG'
        AWS_REGION = "us-west-2"
        NAMESPACE: 'uber'
    }
    stages{
        stage('Cleean Workspace'){
            steps{
                CleeanWs()
            }
        }
        stage('Git Checkout'){
            steps{
                git branch: 'main', url: 'https://github.com/tawfeeq421/uber-clonee.git'
            }
        }
        stage('Install Dependency'){
            steps{
                sh 'npm install'
            }
        }
        stage('Build Next.js App'){
            steps{
                sh 'npm run build'
            }
        }
        stage('Sonar Analysis'){
            environment {
                scannerHome = tool 'sonar'
            }
            steps{
                withSonarQubeEnv('sonarserver'){
                    sh ${scannerHome}/bin/sonar-scanner 
                }
            }
        }
        stage('Quality Gate'){
            steps{
                timeout(time: 1, unit: 'HOURS'){
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Trivy FS Scan'){
            steps{
                sh '''
                trivy fs . \
                --severity HIGH,CRITICAL \
                --format table \
                -o trivy-report.txt || true
                '''
            }
        }
        stage('Docker Build & Push'){
            steps{
                script{
                    docker.withRegistry('https://index.docker.io/v1', 'docker-cred'){
                        def app = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        app.push() 
                    }
                }
            }
        }
        stage('Image Scan'){
            steps{
                sh '''
                trivy image \
                --severity HIGH,CRITICAL \
                --format table \
                -o trivy-image-report.txt \
                ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }
        stage('Kubernetes Prod Deploy'){
            steps{
                withCredentials([[
                    $class 'AmazonWebServicesCredentialsBuilding',
                    credentiaslId: 'aws-creds'
                ]]){
                    sh '''
                    set -e aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER-NAME
                    kubectl apply -f k8s/namespace.yml

                    kubectl apply -f k8s/.

                    kubectl set image deployment/uber-deployment uberapp=$IMAGE -n $NAMESPACE

                    kubectl rollout status deployment/uber-deployment -n $NAMESPACE
                    '''
                }
            }
        }
    }
}