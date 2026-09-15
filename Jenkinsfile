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

        stage('Install FVM') {
            steps {
                sh '''
                    dart pub global activate fvm
                '''
            }
        }

        stage('Install Flutter') {
            steps {
                sh '''
                    export PATH="$HOME/.pub-cache/bin:$PATH"

                    echo "Installing Flutter version from .fvmrc"

                    fvm install

                    echo "Flutter version:"
                    fvm flutter --version
                '''
            }
        }

        stage('Dependencies') {
            steps {
                sh '''
                    export PATH="$HOME/.pub-cache/bin:$PATH"

                    fvm flutter pub get
                '''
            }
        }

        stage('Build') {
            steps {
                script {

                    if (params.BUILD_TYPE == 'apk') {

                        sh """
                            export PATH="\$HOME/.pub-cache/bin:\$PATH"

                            fvm flutter build apk --release \
                                --dart-define=ENV=${params.ENVIRONMENT} \
                                -t lib/main_${params.ENVIRONMENT}.dart
                        """

                    } else {

                        sh """
                            export PATH="\$HOME/.pub-cache/bin:\$PATH"

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

            echo "Build successful!"
        }

        failure {
            echo "Build failed!"
        }
    }
}