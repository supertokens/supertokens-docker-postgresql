#!/usr/bin/env python3

import subprocess
import sys
import argparse
import atexit
from pathlib import Path

RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'

CLUSTER_NAME = "supertokens-helm-test"
POSTGRES_PASSWORD = "supertokens123"
POSTGRES_DATABASE = "supertokens"
HELM_RELEASE_NAME = "supertokens"
POSTGRES_RELEASE_NAME = "postgres"

SCRIPT_DIR = Path(__file__).parent.resolve()
HELM_CHART_DIR = SCRIPT_DIR / "helm-chart"

cluster_created = False
skip_cleanup = False


def log_info(msg):
    print(f"{BLUE}[INFO]{NC} {msg}")


def log_success(msg):
    print(f"{GREEN}[SUCCESS]{NC} {msg}")


def log_warning(msg):
    print(f"{YELLOW}[WARNING]{NC} {msg}")


def log_error(msg):
    print(f"{RED}[ERROR]{NC} {msg}")


def log_step(msg):
    print()
    print(f"{BLUE}========================================{NC}")
    print(f"{BLUE}  {msg}{NC}")
    print(f"{BLUE}========================================{NC}")


def run(cmd, check=True, capture=False, shell=False):
    if isinstance(cmd, str):
        shell = True

    kwargs = {
        "shell": shell,
        "text": True,
    }

    if capture:
        kwargs["capture_output"] = True

    result = subprocess.run(cmd, **kwargs)

    if check and result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, cmd)

    return result


def run_quiet(cmd):
    return subprocess.run(
        cmd, shell=True, text=True,
        capture_output=True
    )


def check_command(name):
    result = run_quiet(f"which {name}")
    if result.returncode != 0:
        log_error(f"{name} is not installed. Please install it first.")
        sys.exit(1)


def show_debug_info():
    log_error("Deployment failed. Showing debug information...")

    print("\n=== SuperTokens Pod Status ===")
    run_quiet("kubectl get pods -l app.kubernetes.io/name=supertokens -o wide")

    print("\n=== SuperTokens Pod Description ===")
    run_quiet("kubectl describe pod -l app.kubernetes.io/name=supertokens")

    print("\n=== SuperTokens Logs ===")
    run_quiet("kubectl logs -l app.kubernetes.io/name=supertokens --tail=100")

    print("\n=== PostgreSQL Pod Status ===")
    run_quiet("kubectl get pods -l app.kubernetes.io/name=postgresql -o wide")

    print("\n=== All Events ===")
    run_quiet("kubectl get events --sort-by='.lastTimestamp'")


def cleanup():
    log_step("Cleanup")

    if skip_cleanup:
        log_warning("Skipping cleanup (--skip-cleanup)")
        return

    log_info("Uninstalling Helm releases...")
    run_quiet(f"helm uninstall {HELM_RELEASE_NAME}")
    run_quiet(f"helm uninstall {POSTGRES_RELEASE_NAME}")

    if cluster_created:
        log_info("Deleting Kind cluster...")
        run_quiet(f"kind delete cluster --name {CLUSTER_NAME}")

    log_success("Cleanup completed")


# Test Functions

def test_lint():
    log_step("Step 1: Helm Lint")
    log_info("Running helm lint...")
    run(f"helm lint {HELM_CHART_DIR}")
    log_success("Helm lint passed")


def test_template_default():
    log_step("Step 2: Helm Template (Default Values)")
    log_info("Rendering templates with default values...")
    run(f"helm template test-release {HELM_CHART_DIR} > /dev/null")
    log_success("Default template rendering passed")


def test_template_database_uri():
    log_step("Step 3: Helm Template (Database URI)")
    log_info("Rendering templates with database URI...")
    run(f'helm template test-release {
        HELM_CHART_DIR} --set database.uri="postgresql://user:pass@host:5432/db" > /dev/null')
    log_success("Database URI template rendering passed")


def test_template_api_keys():
    log_step("Step 4: Helm Template (API Keys)")
    log_info("Rendering templates with API keys enabled...")
    run(f'helm template test-release {
        HELM_CHART_DIR} --set apiKeys.enabled=true --set "apiKeys.keys={{key1,key2}}" > /dev/null')
    log_success("API keys template rendering passed")


def test_template_autoscaling():
    log_step("Step 5: Helm Template (Autoscaling)")
    log_info("Rendering templates with autoscaling enabled...")
    run(f"helm template test-release {
        HELM_CHART_DIR} --set autoscaling.enabled=true > /dev/null")
    log_success("Autoscaling template rendering passed")


def test_template_existing_secret():
    log_step("Step 6: Helm Template (Existing Secret)")
    log_info("Rendering templates with existing secret...")
    run(f"helm template test-release {
        HELM_CHART_DIR} --set existingSecret=my-existing-secret > /dev/null")
    log_success("Existing secret template rendering passed")


def test_template_oauth_options():
    log_step("Step 7: Helm Template (OAuth Options)")
    log_info("Rendering templates with OAuth provider options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set oauth.providerPublicServiceUrl=https://oauth.example.com "
        f"--set oauth.providerAdminServiceUrl=https://admin.oauth.example.com "
        f"--set oauth.providerConsentLoginBaseUrl=https://login.example.com "
        f"--set oauth.clientSecretEncryptionKey=my-encryption-key"
    )
    if result.returncode != 0:
        log_error("OAuth options template rendering failed")
        sys.exit(1)

    output = result.stdout
    checks = [
        ("OAUTH_PROVIDER_PUBLIC_SERVICE_URL", "https://oauth.example.com"),
        ("OAUTH_PROVIDER_ADMIN_SERVICE_URL", "https://admin.oauth.example.com"),
        ("OAUTH_PROVIDER_CONSENT_LOGIN_BASE_URL", "https://login.example.com"),
        ("OAUTH_CLIENT_SECRET_ENCRYPTION_KEY", "my-encryption-key"),
    ]
    for env_var, value in checks:
        if env_var in output and value in output:
            log_success(f"{env_var} renders correctly")
        else:
            log_error(f"{env_var} not found or incorrect value")
            sys.exit(1)

    log_success("OAuth options template rendering passed")


def test_template_firebase_options():
    log_step("Step 8: Helm Template (Firebase Migration Options)")
    log_info("Rendering templates with Firebase migration options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set firebase.passwordHashingSignerKey=firebase-signer-key "
        f"--set firebase.passwordHashingPoolSize=4"
    )
    if result.returncode != 0:
        log_error("Firebase options template rendering failed")
        sys.exit(1)

    output = result.stdout
    if "FIREBASE_PASSWORD_HASHING_SIGNER_KEY" in output and "firebase-signer-key" in output:
        log_success("FIREBASE_PASSWORD_HASHING_SIGNER_KEY renders correctly")
    else:
        log_error(
            "FIREBASE_PASSWORD_HASHING_SIGNER_KEY not found or incorrect value")
        sys.exit(1)

    if "FIREBASE_PASSWORD_HASHING_POOL_SIZE" in output and '"4"' in output:
        log_success("FIREBASE_PASSWORD_HASHING_POOL_SIZE renders correctly")
    else:
        log_error(
            "FIREBASE_PASSWORD_HASHING_POOL_SIZE not found or incorrect value")
        sys.exit(1)

    log_success("Firebase migration options template rendering passed")


def test_template_bulk_migration_options():
    log_step("Step 9: Helm Template (Bulk Migration Options)")
    log_info("Rendering templates with bulk migration options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set bulkMigration.parallelism=8 "
        f"--set bulkMigration.batchSize=1000"
    )
    if result.returncode != 0:
        log_error("Bulk migration options template rendering failed")
        sys.exit(1)

    output = result.stdout
    if "BULK_MIGRATION_PARALLELISM" in output and '"8"' in output:
        log_success("BULK_MIGRATION_PARALLELISM renders correctly")
    else:
        log_error("BULK_MIGRATION_PARALLELISM not found or incorrect value")
        sys.exit(1)

    if "BULK_MIGRATION_BATCH_SIZE" in output and '"1000"' in output:
        log_success("BULK_MIGRATION_BATCH_SIZE renders correctly")
    else:
        log_error("BULK_MIGRATION_BATCH_SIZE not found or incorrect value")
        sys.exit(1)

    log_success("Bulk migration options template rendering passed")


def test_template_webauthn_options():
    log_step("Step 10: Helm Template (WebAuthn Options)")
    log_info("Rendering templates with WebAuthn options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set webauthn.recoverAccountTokenLifetime=7200000"
    )
    if result.returncode != 0:
        log_error("WebAuthn options template rendering failed")
        sys.exit(1)

    output = result.stdout
    if "WEBAUTHN_RECOVER_ACCOUNT_TOKEN_LIFETIME" in output and '"7200000"' in output:
        log_success("WEBAUTHN_RECOVER_ACCOUNT_TOKEN_LIFETIME renders correctly")
    else:
        log_error(
            "WEBAUTHN_RECOVER_ACCOUNT_TOKEN_LIFETIME not found or incorrect value")
        sys.exit(1)

    log_success("WebAuthn options template rendering passed")


def test_template_postgresql_pool_options():
    log_step("Step 11: Helm Template (PostgreSQL Pool Options)")
    log_info("Rendering templates with PostgreSQL connection pool options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set database.tableNamesPrefix=st_ "
        f"--set database.idleConnectionTimeout=60000 "
        f"--set database.minimumIdleConnections=5"
    )
    if result.returncode != 0:
        log_error("PostgreSQL pool options template rendering failed")
        sys.exit(1)

    output = result.stdout
    checks = [
        ("POSTGRESQL_TABLE_NAMES_PREFIX", "st_"),
        ("POSTGRESQL_IDLE_CONNECTION_TIMEOUT", '"60000"'),
        ("POSTGRESQL_MINIMUM_IDLE_CONNECTIONS", '"5"'),
    ]
    for env_var, value in checks:
        if env_var in output and value in output:
            log_success(f"{env_var} renders correctly")
        else:
            log_error(f"{env_var} not found or incorrect value")
            sys.exit(1)

    log_success("PostgreSQL connection pool options template rendering passed")


def test_template_logging_options():
    log_step("Step 12: Helm Template (Logging Options)")
    log_info("Rendering templates with logging path options...")
    result = run_quiet(
        f"helm template test-release {HELM_CHART_DIR} "
        f"--set infoLogPath=/var/log/supertokens/info.log "
        f"--set errorLogPath=/var/log/supertokens/error.log"
    )
    if result.returncode != 0:
        log_error("Logging options template rendering failed")
        sys.exit(1)

    output = result.stdout
    if "INFO_LOG_PATH" in output and "/var/log/supertokens/info.log" in output:
        log_success("INFO_LOG_PATH renders correctly")
    else:
        log_error("INFO_LOG_PATH not found or incorrect value")
        sys.exit(1)

    if "ERROR_LOG_PATH" in output and "/var/log/supertokens/error.log" in output:
        log_success("ERROR_LOG_PATH renders correctly")
    else:
        log_error("ERROR_LOG_PATH not found or incorrect value")
        sys.exit(1)

    log_success("Logging path options template rendering passed")


def test_template_large_integers():
    log_step("Step 13: Verify Large Integers (No Scientific Notation)")

    result = run_quiet(f"helm template test-release {HELM_CHART_DIR}")
    output = result.stdout

    log_info("Checking PASSWORD_RESET_TOKEN_LIFETIME format...")
    if "3600000" in output:
        log_success(
            "PASSWORD_RESET_TOKEN_LIFETIME renders as integer (3600000)")
    else:
        log_error("PASSWORD_RESET_TOKEN_LIFETIME may be in scientific notation")
        sys.exit(1)

    log_info("Checking EMAIL_VERIFICATION_TOKEN_LIFETIME format...")
    if "86400000" in output:
        log_success(
            "EMAIL_VERIFICATION_TOKEN_LIFETIME renders as integer (86400000)")
    else:
        log_error("EMAIL_VERIFICATION_TOKEN_LIFETIME may be in scientific notation")
        sys.exit(1)


def create_kind_cluster():
    global cluster_created
    log_step("Step 14: Create Kind Cluster")

    result = run_quiet("kind get clusters")
    if CLUSTER_NAME in result.stdout.split():
        log_warning(f"Kind cluster '{CLUSTER_NAME}' already exists")
        run(f"kubectl config use-context kind-{CLUSTER_NAME}")
    else:
        log_info(f"Creating Kind cluster '{CLUSTER_NAME}'...")
        run(f"kind create cluster --name {CLUSTER_NAME} --wait 120s")
        cluster_created = True

    log_info("Verifying cluster is running...")
    run("kubectl cluster-info")
    run("kubectl get nodes")
    log_success("Kind cluster is ready")


def deploy_postgresql():
    log_step("Step 15: Deploy PostgreSQL")

    log_info("Adding Bitnami Helm repository...")
    run_quiet("helm repo add bitnami https://charts.bitnami.com/bitnami")
    run("helm repo update")

    log_info("Installing PostgreSQL...")
    run(f"""helm install {POSTGRES_RELEASE_NAME} bitnami/postgresql \
        --set auth.postgresPassword={POSTGRES_PASSWORD} \
        --set auth.database={POSTGRES_DATABASE} \
        --set primary.persistence.size=1Gi \
        --wait --timeout 120s""")

    log_info("Waiting for PostgreSQL to be ready...")
    run("kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=120s")

    log_info("Verifying PostgreSQL is running...")
    run("kubectl get pods -l app.kubernetes.io/name=postgresql")
    log_success("PostgreSQL is ready")


def deploy_supertokens():
    log_step("Step 16: Deploy SuperTokens")

    log_info("Installing SuperTokens Helm chart...")
    run(f"""helm install {HELM_RELEASE_NAME} {HELM_CHART_DIR} \
        --set database.host={POSTGRES_RELEASE_NAME}-postgresql \
        --set database.port=5432 \
        --set database.name={POSTGRES_DATABASE} \
        --set database.user=postgres \
        --set database.password={POSTGRES_PASSWORD} \
        --set disableTelemetry=true \
        --wait --timeout 120s""")

    log_info("Waiting for deployment rollout...")
    run("kubectl rollout status deployment/supertokens --timeout=120s")

    log_info("Verifying SuperTokens pod is running...")
    run("kubectl get pods -l app.kubernetes.io/name=supertokens")
    log_success("SuperTokens is deployed")


def test_helm_test():
    log_step("Step 17: Run Helm Test")
    log_info("Running helm test...")
    run(f"helm test {HELM_RELEASE_NAME} --timeout 60s")
    log_success("Helm test passed")


def test_hello_endpoint():
    log_step("Step 18: Test /hello Endpoint")
    log_info("Testing /hello endpoint...")

    result = run_quiet(
        "kubectl run test-hello --rm -i --restart=Never "
        "--image=curlimages/curl "
        "-- curl -sf http://supertokens:3567/hello"
    )

    if "Hello" in result.stdout:
        log_success("/hello endpoint returned 'Hello'")
    else:
        log_error(
            f"/hello endpoint returned unexpected response: {result.stdout}")
        sys.exit(1)


def test_apiversion_endpoint():
    log_step("Step 19: Test /apiversion Endpoint")
    log_info("Testing /apiversion endpoint...")

    result = run_quiet(
        "kubectl run test-apiversion --rm -i --restart=Never "
        "--image=curlimages/curl "
        "-- curl -sf http://supertokens:3567/apiversion"
    )

    if "versions" in result.stdout:
        log_success("/apiversion endpoint returned versions list")
        log_info(f"Response: {result.stdout.strip()}")
    else:
        log_error(
            f"/apiversion endpoint returned unexpected response: {result.stdout}")
        sys.exit(1)


def test_upgrade():
    log_step("Step 20: Test Helm Upgrade")

    log_info("Upgrading with new values (LOG_LEVEL=DEBUG)...")
    run(f"""helm upgrade {HELM_RELEASE_NAME} {HELM_CHART_DIR} \
        --set database.host={POSTGRES_RELEASE_NAME}-postgresql \
        --set database.port=5432 \
        --set database.name={POSTGRES_DATABASE} \
        --set database.user=postgres \
        --set database.password={POSTGRES_PASSWORD} \
        --set disableTelemetry=true \
        --set logLevel=DEBUG \
        --wait --timeout 120s""")

    log_info("Waiting for rollout...")
    run("kubectl rollout status deployment/supertokens --timeout=60s")

    log_info("Verifying LOG_LEVEL is set to DEBUG...")
    result = run_quiet(
        "kubectl get deployment supertokens -o jsonpath='{.spec.template.spec.containers[0].env}'"
    )

    if "DEBUG" in result.stdout:
        log_success("LOG_LEVEL is correctly set to DEBUG")
    else:
        log_error("LOG_LEVEL was not updated")
        sys.exit(1)

    log_info("Running helm test after upgrade...")
    run(f"helm test {HELM_RELEASE_NAME} --timeout 60s")
    log_success("Helm upgrade test passed")


def print_summary():
    log_step("Test Summary")
    print()
    log_success("All tests passed!")
    print()
    print("Tests executed:")
    tests = [
        "Helm lint",
        "Template rendering (default values)",
        "Template rendering (database URI)",
        "Template rendering (API keys)",
        "Template rendering (autoscaling)",
        "Template rendering (existing secret)",
        "Template rendering (OAuth options)",
        "Template rendering (bulk migration options)",
        "Template rendering (WebAuthn options)",
        "Template rendering (PostgreSQL pool options)",
        "Template rendering (logging options)",
        "Large integer formatting verification",
        "Kind cluster creation",
        "PostgreSQL deployment",
        "SuperTokens deployment",
        "Helm test",
        "/hello endpoint test",
        "/apiversion endpoint test",
        "Helm upgrade test",
    ]
    for test in tests:
        print(f"  ✓ {test}")
    print()


def main():
    global skip_cleanup

    parser = argparse.ArgumentParser(
        description="SuperTokens Helm Chart Test Suite")
    parser.add_argument("--lint-only", action="store_true",
                        help="Run only lint and template tests (no cluster required)")
    parser.add_argument("--skip-cleanup", action="store_true",
                        help="Don't delete cluster and releases after tests")
    args = parser.parse_args()

    skip_cleanup = args.skip_cleanup

    print()
    print(f"{GREEN}╔════════════════════════════════════════════════════════╗{NC}")
    print(f"{GREEN}║       SuperTokens Helm Chart Test Suite                ║{NC}")
    print(f"{GREEN}╚════════════════════════════════════════════════════════╝{NC}")
    print()

    log_step("Prerequisites Check")
    check_command("helm")
    log_success("helm is installed")

    if not args.lint_only:
        check_command("kind")
        log_success("kind is installed")
        check_command("kubectl")
        log_success("kubectl is installed")
        atexit.register(cleanup)

    try:
        test_lint()
        test_template_default()
        test_template_database_uri()
        test_template_api_keys()
        test_template_autoscaling()
        test_template_existing_secret()
        test_template_oauth_options()
        test_template_bulk_migration_options()
        test_template_webauthn_options()
        test_template_postgresql_pool_options()
        test_template_logging_options()
        test_template_large_integers()

        if args.lint_only:
            log_step("Lint Tests Complete")
            log_success("All lint and template tests passed!")
            return

        create_kind_cluster()
        deploy_postgresql()
        deploy_supertokens()
        test_helm_test()
        test_hello_endpoint()
        test_apiversion_endpoint()
        test_upgrade()

        print_summary()

    except (subprocess.CalledProcessError, Exception) as e:
        show_debug_info()
        log_error(f"Test failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
