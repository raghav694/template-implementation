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

def androidSdkLooksValid(String root) {
    if (!root || root == '.') {
        return false
    }
    return fileExists("${root}/platform-tools") ||
        fileExists("${root}/cmdline-tools") ||
        fileExists("${root}/build-tools") ||
        fileExists("${root}/ndk")
}

def androidSdkFromRoot(String root) {
    if (!root || root == '.') {
        return null
    }
    if (androidSdkLooksValid(root)) {
        return root
    }
    if (androidSdkLooksValid("${root}/sdk")) {
        return "${root}/sdk"
    }
    return null
}

def androidSdkWritable(String root) {
    return sh(
        script: "touch '${root}/.jenkins-write-test' && rm -f '${root}/.jenkins-write-test'",
        returnStatus: true
    ) == 0
}

def listSubdirs(String parent) {
    def raw = sh(
        script: "find '${parent}' -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null || true",
        returnStdout: true
    ).trim()
    if (!raw) {
        return []
    }
    def dirs = []
    for (def line : raw.split('\n')) {
        def path = line.trim()
        if (path) {
            dirs.add(path)
        }
    }
    return dirs
}

def resolveAndroidSdk() {
    def homeDir = env.HOME ?: '/var/lib/jenkins'
    def jenkinsHome = env.JENKINS_HOME ?: homeDir
    def names = ['Android-SDK', 'Android SDK', 'android-sdk', 'Android']
    def candidates = []

    // Always call tool() so automatic installers run. Generic Tool Home is often
    // '.' (same Flutter trap); that return value is not a real SDK path.
    for (def toolName : names) {
        try {
            def toolHome = tool(name: toolName)
            echo "Android tool '${toolName}' home: ${toolHome}"
            if (toolHome && toolHome != '.') {
                candidates.add(toolHome)
            } else {
                echo "Android tool '${toolName}' Home is '${toolHome}'. Looking under Jenkins tools cache."
            }
        } catch (Exception e) {
            echo "tool('${toolName}') failed: ${e}"
        }
    }

    def toolRoots = [
        "${jenkinsHome}/tools/io.jenkins.plugins.generic_tool.GenericToolInstallation",
        "${jenkinsHome}/tools/com.cloudbees.jenkins.plugins.customtools.CustomTool",
        "${homeDir}/tools/io.jenkins.plugins.generic_tool.GenericToolInstallation",
    ]
    for (def root : toolRoots) {
        sh "ls -la '${root}' 2>/dev/null || echo '(no tools at ${root})'"
        for (def toolName : names) {
            candidates.add("${root}/${toolName}")
        }
        for (def child : listSubdirs(root)) {
            candidates.add(child)
        }
    }

    candidates.add("${homeDir}/android-sdk")
    candidates.add("${homeDir}/Android/Sdk")

    def seen = []
    def unwritable = null
    for (def root : candidates) {
        if (!root || root == '.' || seen.contains(root)) {
            continue
        }
        seen.add(root)
        def sdk = androidSdkFromRoot(root)
        if (!sdk) {
            continue
        }
        echo "Found Android SDK at ${sdk}"
        if (androidSdkWritable(sdk)) {
            echo "Using writable Android SDK at ${sdk}"
            return sdk
        }
        echo "Skipping ${sdk}: jenkins cannot write there (NDK install would fail)."
        if (!unwritable) {
            unwritable = sdk
        }
    }

    if (unwritable) {
        error(
            "Found Android SDK at ${unwritable} but jenkins cannot write there. " +
            "Point Generic Tool Home at a jenkins-owned SDK, or run: " +
            "sudo chown -R jenkins:jenkins '${unwritable}'"
        )
    }

    error(
        "No usable Android SDK on this agent. Generic Tool Home is often '.' which is not an SDK. " +
        "Set Home to the SDK root (folder with platform-tools), or install automatically so files land in " +
        "${jenkinsHome}/tools/io.jenkins.plugins.generic_tool.GenericToolInstallation/Android-SDK"
    )
}

def markStage(String name) {
    env.LAST_STAGE = name
}

def readAppName() {
    if (!fileExists('project_config.yaml')) {
        return 'App'
    }
    def text = readFile('project_config.yaml')
    def matcher = text =~ /(?m)^ {2}name:\s*"([^"]+)"/
    return matcher.find() ? matcher.group(1) : 'App'
}

def readDotEnvValue(String path, String key) {
    if (!fileExists(path)) {
        return ''
    }
    def value = ''
    readFile(path).split('\n').each { raw ->
        def line = raw.replaceAll('\r', '')
        if (line.startsWith("${key}=")) {
            value = line.substring(key.length() + 1)
        }
    }
    return value.trim()
}

def copyJenkinsSecretFile(String credentialsId, String dest) {
    withCredentials([file(credentialsId: credentialsId, variable: 'SECRET_ENV_FILE')]) {
        sh "cp \"\$SECRET_ENV_FILE\" '${dest}' && chmod 600 '${dest}'"
    }
    echo "Wrote ${dest} from Jenkins credential '${credentialsId}'"
}

def ensureDotEnvAssets() {
    // pubspec lists both .env.dev and .env.prod as assets, so both must exist
    // even when building a single flavor. They are gitignored; Jenkins secret
    // files supply them (flutter-test-env-dev / flutter-test-env-prod).
    copyJenkinsSecretFile('flutter-test-env-dev', '.env.dev')

    def wroteProd = false
    try {
        copyJenkinsSecretFile('flutter-test-env-prod', '.env.prod')
        wroteProd = true
    } catch (Exception e) {
        echo "Jenkins credential flutter-test-env-prod not available: ${e}"
    }

    if (!wroteProd) {
        if (params.ENVIRONMENT == 'prod') {
            error(
                "Prod builds need a Jenkins secret file credential named " +
                "flutter-test-env-prod (contents of .env.prod)."
            )
        }
        if (fileExists('.env.prod.example')) {
            sh 'cp .env.prod.example .env.prod'
        } else {
            writeFile file: '.env.prod', text: '# placeholder so pubspec asset .env.prod exists\n'
        }
        echo 'Wrote placeholder .env.prod (required pubspec asset for a dev build)'
    }
}

def loadSlackEnv() {
    def flavorFile = ".env.${params.ENVIRONMENT}"
    def homeFile = "${env.HOME}/.env.${params.ENVIRONMENT}"
    def paths = [flavorFile, homeFile, '.slack.env', "${env.HOME}/.slack.env"]
    def token = ''
    def channel = ''
    paths.each { path ->
        if (!token) {
            token = readDotEnvValue(path, 'SLACK_API_TOKEN')
        }
        if (!token) {
            token = readDotEnvValue(path, 'SLACK_BOT_TOKEN')
        }
        if (!channel) {
            channel = readDotEnvValue(path, 'SLACK_CHANNEL_ID')
        }
    }
    env.SLACK_API_TOKEN = token
    env.SLACK_CHANNEL_ID = channel
    if (token && channel) {
        echo "Slack env loaded for ${params.ENVIRONMENT}"
    } else {
        echo "Slack skipped: set SLACK_API_TOKEN and SLACK_CHANNEL_ID in ${flavorFile} (or ${homeFile})"
    }
}

def slackConfigured() {
    return env.SLACK_API_TOKEN?.trim() && env.SLACK_CHANNEL_ID?.trim()
}

def slackErrorSnippet() {
    try {
        def logLines = currentBuild.rawBuild.getLog(200)
        def interesting = logLines.findAll { line ->
            def lower = line.toLowerCase()
            lower.contains('what went wrong') ||
                lower.contains('failure:') ||
                lower.contains('error:') ||
                lower.contains('fatal:') ||
                lower.contains('failed to') ||
                lower.contains('exception') ||
                lower.contains('not found')
        }
        if (interesting.isEmpty()) {
            interesting = logLines.findAll { it?.trim() }
        }
        def n = Math.min(2, interesting.size())
        if (n == 0) {
            return "See ${env.BUILD_URL}console"
        }
        return interesting.subList(interesting.size() - n, interesting.size())
            .collect { it.take(240) }
            .join('\n')
    } catch (Exception ignored) {
        return "See ${env.BUILD_URL}console"
    }
}

def slackNotify(String text) {
    if (!slackConfigured()) {
        echo 'Slack not configured; skipping message'
        return
    }
    try {
        writeFile file: '.ci-slack-message.txt', text: text
        sh(script: '''
python3 - <<'PY'
import json, os, urllib.request

text = open(".ci-slack-message.txt", encoding="utf-8").read()
body = json.dumps(
    {"channel": os.environ["SLACK_CHANNEL_ID"], "text": text},
    ensure_ascii=False,
).encode("utf-8")
req = urllib.request.Request(
    "https://slack.com/api/chat.postMessage",
    data=body,
    headers={
        "Authorization": "Bearer " + os.environ["SLACK_API_TOKEN"],
        "Content-Type": "application/json; charset=utf-8",
    },
    method="POST",
)
with urllib.request.urlopen(req, timeout=60) as resp:
    payload = json.loads(resp.read().decode())
if not payload.get("ok"):
    raise SystemExit("Slack chat.postMessage failed: " + json.dumps(payload))
print("Slack message sent")
PY
        ''', returnStatus: true)
    } catch (Exception e) {
        echo "Slack message failed: ${e}"
    }
}

def findBuiltArtifact() {
    def flavor = params.ENVIRONMENT
    if (params.BUILD_TYPE == 'apk') {
        def flavorApk = "build/app/outputs/flutter-apk/app-${flavor}-release.apk"
        def defaultApk = 'build/app/outputs/flutter-apk/app-release.apk'
        if (fileExists(flavorApk)) {
            return flavorApk
        }
        if (fileExists(defaultApk)) {
            return defaultApk
        }
        return null
    }
    def flavorAab = "build/app/outputs/bundle/${flavor}Release/app-${flavor}-release.aab"
    def defaultAab = 'build/app/outputs/bundle/release/app-release.aab'
    if (fileExists(flavorAab)) {
        return flavorAab
    }
    if (fileExists(defaultAab)) {
        return defaultAab
    }
    return null
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
        FVM_CACHE_PATH = "${env.HOME}/fvm"
        GIT_TERMINAL_PROMPT = '0'
        LAST_STAGE = 'unknown'
        APP_DISPLAY_NAME = 'App'
    }

    stages {
        stage('Checkout') {
            steps {
                script { markStage('Checkout') }
                deleteDir()

                git(
                    branch: params.BRANCH,
                    url: 'https://github.com/raghav694/template-implementation.git',
                    credentialsId: 'github-vc-tests'
                )

                script {
                    ensureDotEnvAssets()
                    loadSlackEnv()
                    env.APP_DISPLAY_NAME = readAppName()
                    slackNotify(
                        "Build initiated for ${env.APP_DISPLAY_NAME} and branch `${params.BRANCH}` " +
                        "(${params.ENVIRONMENT} ${params.BUILD_TYPE})."
                    )
                }
            }
        }

        stage('Setup FVM') {
            steps {
                script {
                    markStage('Setup FVM')
                    def flutterBin = resolveFlutterBin()
                    def androidSdk = resolveAndroidSdk()
                    env.ANDROID_SDK_ROOT = androidSdk
                    env.ANDROID_HOME = androidSdk
                    def ndk = "${androidSdk}/ndk/27.0.12077973"
                    if (fileExists(ndk)) {
                        env.ANDROID_NDK_HOME = ndk
                    }
                    env.PATH = [
                        flutterBin,
                        "${androidSdk}/platform-tools",
                        "${androidSdk}/cmdline-tools/latest/bin",
                        "${env.HOME}/.pub-cache/bin",
                        env.PATH,
                    ].join(':')
                    echo "Using dart at ${flutterBin}/dart"
                    echo "ANDROID_SDK_ROOT=${env.ANDROID_SDK_ROOT}"
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
                script { markStage('Dependencies') }
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-vc-tests',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e
                        export GIT_ASKPASS="$HOME/.ci-git-askpass"
                        cat > "$GIT_ASKPASS" <<'EOF'
#!/bin/sh
case "$1" in
  *[Uu]sername*) echo "$GIT_USERNAME" ;;
  *) echo "$GIT_PASSWORD" ;;
esac
EOF
                        chmod 700 "$GIT_ASKPASS"
                        fvm flutter pub get
                    '''
                }
            }
        }

        stage('Build') {
            steps {
                script { markStage('Build') }
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-vc-tests',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    script {
                        def flavor = params.ENVIRONMENT
                        def target = "lib/main_${flavor}.dart"
                        env.GIT_ASKPASS = "${env.HOME}/.ci-git-askpass"

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
    }

    post {
        success {
            archiveArtifacts(
                artifacts: 'build/app/outputs/**/*.apk,build/app/outputs/**/*.aab',
                fingerprint: true
            )

            script {
                if (!slackConfigured()) {
                    echo 'Slack not configured; skipping upload'
                    return
                }
                def artifact = findBuiltArtifact()
                def comment =
                    "Build SUCCESSFUL for ${env.APP_DISPLAY_NAME} " +
                    "(branch `${params.BRANCH}`, ${params.ENVIRONMENT} ${params.BUILD_TYPE})."
                if (artifact) {
                    writeFile file: '.ci-slack-comment.txt', text: comment
                    def status = sh(
                        script: "bash scripts/ci_slack.sh upload '${artifact}'",
                        returnStatus: true
                    )
                    if (status != 0) {
                        echo 'Slack upload failed; sending text only'
                        slackNotify(comment + "\nArtifact: ${artifact}")
                    }
                } else {
                    slackNotify(comment + '\nNo APK/AAB file was found to upload.')
                }
            }

            echo "====================================="
            echo "BUILD SUCCESSFUL"
            echo "Branch: ${params.BRANCH}"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Build Type: ${params.BUILD_TYPE}"
            echo "====================================="
        }

        failure {
            script {
                def snippet = slackErrorSnippet()
                slackNotify(
                    "Build FAILED for ${env.APP_DISPLAY_NAME} on branch `${params.BRANCH}` " +
                    "at stage *${env.LAST_STAGE}*.\n${snippet}"
                )
            }

            echo "====================================="
            echo "BUILD FAILED"
            echo "====================================="
        }

        always {
            sh 'rm -f "$HOME/.ci-git-askpass" .ci-slack-message.txt .ci-slack-comment.txt'
        }
    }
}
