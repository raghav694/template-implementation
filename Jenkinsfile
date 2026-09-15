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
        FLUTTER_HOME = "${WORKSPACE}/.flutter"
        PATH = "${WORKSPACE}/.flutter/bin:${HOME}/.pub-cache/bin:${PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                deleteDir()

                git(
                    branch: params.BRANCH,
                    url: 'https://github.com/raghav694/template-implementation.git'
                )
            }
        }

        stage('Install Flutter & Dart') {
            steps {
                sh '''
                    set -e

                    echo "Installing Flutter..."

                    if [ ! -d "$FLUTTER_HOME" ]; then
                        git clone \
                            --depth 1 \
                            --branch stable \
                            https://github.com/flutter/flutter.git \
                            "$FLUTTER_HOME"
                    fi

                    export PATH="$FLUTTER_HOME/bin:$HOME/.pub-cache/bin:$PATH"

                    echo "Flutter:"
                    flutter --version

                    echo "Dart:"
                    dart --version
                '''
            }
        }

        stage('Install FVM') {
            steps {
                sh '''
                    set -e

                    export PATH="$FLUTTER_HOME/bin:$HOME/.pub-cache/bin:$PATH"

                    echo "Installing FVM..."

                    dart pub global activate fvm

                    echo "FVM:"
                    fvm --version
                '''
            }
        }

        stage('Install Project Flutter Version') {
            steps {
                sh '''
                    set -e

                    export PATH="$FLUTTER_HOME/bin:$HOME/.pub-cache/bin:$PATH"

                    echo "Installing Flutter version from .fvmrc..."

                    fvm install

                    echo "Project Flutter version:"
                    fvm flutter --version

                    echo "Project Dart version:"
                    fvm dart --version
                '''
            }
        }

        stage('Dependencies') {
            steps {
                sh '''
                    set -e

                    export PATH="$FLUTTER_HOME/bin:$HOME/.pub-cache/bin:$PATH"

                    fvm flutter pub get
                '''
            }
        }

        stage('Build') {
            steps {
                script {

                    if (params.BUILD_TYPE == 'apk') {

                        sh """
                            set -e

                            export PATH="\$FLUTTER_HOME/bin:\$HOME/.pub-cache/bin:\$PATH"

                            fvm flutter build apk --release \
                                --dart-define=ENV=${params.ENVIRONMENT} \
                                -t lib/main_${params.ENVIRONMENT}.dart
                        """

                    } else {

                        sh """
                            set -e

                            export PATH="\$FLUTTER_HOME/bin:\$HOME/.pub-cache/bin:\$PATH"

                            fvm flutter build appbundle --release \
                                --dart-define=ENV=${params.ENVIRONMENT} \
                                -t lib/main_${params.ENVIRONMENT}.dart
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