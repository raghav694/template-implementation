def flutterBinIfPresent(String root) {
    if (!root || root == '.') {
        return null
    }
    if (fileExists("${root}/bin/dart")) {
        return "${root}/bin"
    }
    if (fileExists("${root}/flutter/bin/dart")) {
        return "${root}/flutter/bin"
    }
    return null
}

def resolveFlutterBin() {
    def homeDir = env.HOME ?: '/var/lib/jenkins'
    def bootstrap = "${homeDir}/flutter-bootstrap"
    def candidates = [
        bootstrap,
        "${homeDir}/flutter",
        '/opt/flutter',
        '/usr/local/flutter',
        "${env.JENKINS_HOME ?: '/var/lib/jenkins'}/tools/io.jenkins.plugins.generic_tool.GenericToolInstallation/Flutter-3.35.1",
    ]

    try {
        def toolHome = tool 'Flutter-3.35.1'
        echo "Flutter Generic Tool home: ${toolHome}"
        if (toolHome && toolHome != '.') {
            candidates.add(0, toolHome)
        } else {
            echo "Ignoring Generic Tool Home '${toolHome}'. It must be an absolute SDK path, not '.'."
        }
    } catch (ignored) {
        echo 'Generic Tool Flutter-3.35.1 is not configured; using a cached bootstrap SDK.'
    }

    for (def root : candidates) {
        def bin = flutterBinIfPresent(root)
        if (bin) {
            echo "Using Flutter at ${bin}"
            return bin
        }
    }

    echo "No Flutter SDK found. Cloning 3.35.1 once into ${bootstrap}"
    sh """
        set -e
        git clone --depth 1 --branch 3.35.1 https://github.com/flutter/flutter.git '${bootstrap}'
    """

    def bin = flutterBinIfPresent(bootstrap)
    if (!bin) {
        error("Failed to install bootstrap Flutter at ${bootstrap}")
    }
    return bin
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
