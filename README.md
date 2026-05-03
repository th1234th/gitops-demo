# GitOps Demo

A dedicated GitOps folder demonstrating a complete CI/CD workflow with:

- GitHub Actions for CI
- Docker image build and registry push
- Argo CD GitOps deployment
- Kubernetes deployment on Minikube/EKS
- Ingress with NGINX + TLS
- Observability with Prometheus, Grafana, and Loki
- Auto rollback using Argo Rollouts

## Layout

- `app.py` - sample Flask app
- `Dockerfile` - build container image
- `requirements.txt` - Python dependencies
- `chart/` - Helm chart for the application and Argo Rollouts
- `k8s/` - Argo CD application and observability manifests

## Quick start

1. Install Minikube, kubectl, Helm, Argo CD, and an NGINX ingress controller.
2. Configure Docker Hub secrets in GitHub Actions:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
3. Push this repository to GitHub.
4. Enable Argo CD to track `gitops-demo/chart` and deploy the Helm release.
5. Use GitHub Actions to build and publish both `latest` and a short SHA-tagged image.

## Local TLS setup

To create and install a self-signed certificate for `ci-cd.local`, run:

```bash
chmod +x scripts/setup-tls.sh
./scripts/setup-tls.sh
```

To apply the preconfigured ingress and resolve the host mapping automatically, run:

```bash
chmod +x scripts/setup-ingress.sh
./scripts/setup-ingress.sh
```

If you want the script to update `/etc/hosts` directly, run it with `sudo`:

```bash
sudo ./scripts/setup-ingress.sh --apply-hosts
```

## Notes

- Replace `YOUR_DOCKERHUB_USERNAME` and repository URL placeholders before production.
- TLS is configured with a placeholder secret. Create or install a valid certificate for `ci-cd.local`.
