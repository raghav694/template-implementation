def resolveFlutterBin() {
    def home = tool 'Flutter-3.35.1'
    echo "Flutter tool home: ${home}"

    if (fileExists("${home}/bin/dart")) {
        return "${home}/bin"
    }
    if (fileExists("${home}/flutter/bin/dart")) {
        return "${home}/flutter/bin"
    }

    error(
        "dart not found under ${home}. " +
        "Set Generic Tool Home to the Flutter SDK root (the folder that contains bin/flutter). " +
        "If you used Extract *.zip/*.tar.gz, Subdirectory of extracted archive must be flutter."
    )
}

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

    environment {
        PUB_CACHE = "${env.HOME}/.pub-cache"
        FVM_HOME = "${env.HOME}/fvm"
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()

                git(
                    branch: params.BRANCH,
                    url: 'https://github.com/raghav694/template-implementation.git',
                    credentialsId: 'github-vc-tests'
                )
            }
        }

        stage('Setup FVM') {
            steps {
                script {
                    def flutterBin = resolveFlutterBin()
                    env.PATH = "${flutterBin}:${env.HOME}/.pub-cache/bin:${env.PATH}"
                    echo "Using dart at ${flutterBin}/dart"
                }

                sh '''
                    set -e

                    command -v dart
                    dart --version

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
