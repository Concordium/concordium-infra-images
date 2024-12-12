pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'docker run \
                    -w /mnt/packer \
                    --mount type=bind,source="$(pwd)"/packer/,target=/mnt/packer/ \
                    hashicorp/packer:latest build -color=false jenkins-linux-worker.pkr.hcl'
            }
        }
    }
}
