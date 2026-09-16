pipeline {
    agent any

    parameters {
        string(
            name: 'BRANCH',
            defaultValue: 'dev',
            description: 'Enter the Git branch to build'
        )

        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Select environment'
        )

        choice(
            name: 'BUILD_TYPE',
            choices: ['apk', 'aab'],
            description: 'Select build type'
        )
    }

    // Bootstrap Flutter from Manage Jenkins → Tools → Generic Tool (name: Flutter-3.35.1).
    // Project Flutter version comes from .fvmrc via FVM. Cache lives in the Jenkins
    // user home so deleteDir() does not force a re-download every build.
    environment {
        PATH = "${tool 'Flutter-3.35.1'}/bin:${env.HOME}/.pub-cache/bin:${env.PATH}"
        PUB_CACHE = "${env.HOME}/.pub-cache"
        FVM_HOME = "${env.HOME}/fvm"
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()

                git(
                    branch: params.BRANCH,
                    url: 'git@github.com:raghav694/template-implementation.git',
                    credentialsId: 'github-vc-tests'
                )
            }
        }

        stage('Setup FVM') {
            steps {
                sh '''
                    set -e

                    dart pub global activate fvm
                    fvm install

                    echo "FVM:"
                    fvm --version
                    echo "Project Flutter:"
                    fvm flutter --version
                    echo "Project Dart:"
                    fvm dart --version
                '''
            }
        }

        stage('Dependencies') {
            steps {
                sh '''
                    set -e
                    fvm flutter pub get
                '''
            }
        }

        stage('Build') {
            steps {
                script {
                    def flavor = params.ENVIRONMENT
                    def target = "lib/main_${flavor}.dart"

                    if (params.BUILD_TYPE == 'apk') {
                        sh """
                            set -e
                            fvm flutter build apk --release --flavor ${flavor} -t ${target}
                        """
                    } else {
                        sh """
                            set -e
                            fvm flutter build appbundle --release --flavor ${flavor} -t ${target}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts(
                artifacts: 'build/app/outputs/**/*.apk,build/app/outputs/**/*.aab',
                fingerprint: true
            )

            echo "====================================="
            echo "BUILD SUCCESSFUL"
            echo "Branch: ${params.BRANCH}"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Build Type: ${params.BUILD_TYPE}"
            echo "====================================="
        }

        failure {
            echo "====================================="
            echo "BUILD FAILED"
            echo "====================================="
        }
    }
}
