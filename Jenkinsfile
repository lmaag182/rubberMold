pipeline {
  agent any
  stages {
    stage('initialize') {
      parallel {
        stage('initialize') {
          steps {
            sh 'echo "first step yeees"'
          }
        }

        stage('Initialize 2') {
          steps {
            sleep 3
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