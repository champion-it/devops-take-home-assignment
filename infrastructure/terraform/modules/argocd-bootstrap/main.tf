terraform {
  required_version = ">= 1.5.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.27"
    }
  }
}

# ------------------------------------------------------------------------
# Phase 1: ingress-nginx
#   Installed via Helm directly because it's a dependency of Argo CD's Ingress
#   (Argo CD's UI is served through nginx). Solves the chicken-and-egg of
#   "Argo CD manages ingress-nginx but Argo CD UI needs ingress-nginx".
# ------------------------------------------------------------------------
resource "kubernetes_namespace" "ingress_nginx" {
  metadata { name = "ingress-nginx" }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [yamlencode({
    controller = {
      kind = "DaemonSet"
      service = {
        type = "NodePort"
        nodePorts = {
          http  = var.ingress_nodeport_http
          https = var.ingress_nodeport_https
        }
        externalTrafficPolicy = "Local"
      }
      config = {
        use-forwarded-headers = "true"
        enable-real-ip        = "true"
      }
      metrics = {
        enabled = true
        serviceMonitor = {
          enabled          = true
          additionalLabels = { release = "kps" }
        }
      }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }
  })]

  wait    = true
  timeout = 600
}

# ------------------------------------------------------------------------
# Phase 2: Argo CD itself
# ------------------------------------------------------------------------
resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.12"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [yamlencode({
    global = {
      domain = var.argocd_hostname
    }
    configs = {
      params = {
        # Disable internal TLS — TLS is terminated upstream (or skipped on internal LAN).
        "server.insecure" = "true"
      }
      cm = {
        "url"          = "https://${var.argocd_hostname}"
        "exec.enabled" = "false"
      }
      rbac = {
        "policy.default" = "role:readonly"
      }
    }
    server = {
      replicas = 2
      service = {
        type = "ClusterIP"
      }
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        hostname         = var.argocd_hostname
        annotations = {
          # Argo CD UI uses gRPC for some endpoints — nginx needs to know.
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
          "nginx.ingress.kubernetes.io/ssl-redirect"     = "false"
          # Defense in depth: only allow from VPC CIDR ranges.
          "nginx.ingress.kubernetes.io/whitelist-source-range" = join(",", var.admin_cidr_allowlist)
        }
        tls = false
      }
    }
    controller = {
      replicas = 1
      resources = {
        requests = { cpu = "200m", memory = "512Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }
    repoServer     = { replicas = 2 }
    applicationSet = { replicas = 2 }
    dex            = { enabled = false }
    redis-ha       = { enabled = false } # use single redis for cost — switch to HA in prod
    notifications  = { enabled = false }
  })]

  depends_on = [helm_release.ingress_nginx]
  wait       = true
  timeout    = 900
}

# ------------------------------------------------------------------------
# Phase 3: Root Application (app-of-apps)
#   This is the ONE manifest Terraform applies into Argo CD. It points at
#   gitops/application-argocd/ in the repo. From here on, Argo CD self-manages everything.
# ------------------------------------------------------------------------
resource "kubernetes_manifest" "root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "root"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo
        targetRevision = var.git_revision
        path           = var.git_apps_path
        directory      = { recurse = true }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true", "ServerSideApply=true"]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
