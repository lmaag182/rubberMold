pipeline {
  agent any
  stages {
    stage('initialize') {
      parallel {
        stage('initialize_1') {
          steps {
            sh 'echo "first step yeees"'
          }
        }

        stage('Initialize_2') {
          steps {
            sleep 3
          }
        }

        stage('Forced Fail') {
          steps {
            sh 'exit 1'
          }
        }

      }
    }

    stage('build') {
      steps {
        sh 'echo "build step"'
      }
    }

  }
}