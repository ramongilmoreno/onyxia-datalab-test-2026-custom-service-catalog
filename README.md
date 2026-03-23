Example of Onyxia custom services catalog

# Helm repo addressable via the GitHub raw user content:

https://raw.githubusercontent.com/ramongilmoreno/onyxia-datalab-test-2026-custom-service-catalog/refs/heads/main/index.yaml

# Copilot instructions:

> How to create a custom Onyxia Datalabs service?

Great question! In Onyxia, a “service” is just a Helm chart exposed in the Service Catalog. So “creating a custom Onyxia Datalab service” = **packaging your app as a Helm chart, publishing it in a Helm repository, and registering that repo as a catalog in Onyxia**. Below is a practical, end‑to‑end recipe you can follow.

***

## Overview of the steps

1.  **Create (or adapt) a Helm chart** for your app.
2.  **Add a `values.schema.json`** (with Onyxia-specific hints) so Onyxia can render a friendly form.
3.  **Publish the chart in a Helm repo** (e.g., GitHub Pages).
4.  **Register that repo as a Catalog in Onyxia** (`onyxia.api.catalogs`).
5.  **Test & iterate** (defaults, policies, visibility, etc.).

Onyxia is deliberately modeled as a UI on top of Helm: each chart becomes a service card; its `values.schema.json` drives the on-screen form; and Onyxia injects user/region defaults when rendering values. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)

***

## 1) Create a Helm chart

If you don’t already have one:

```bash
helm create my-service
```

Key files to care about in a Helm chart:

*   `Chart.yaml`: metadata (name, version, description).
*   `values.yaml`: default configuration.
*   `values.schema.json`: **JSON Schema** that constrains/annotates `values`. Helm validates against it, and Onyxia uses it to build the service form. [\[helm.sh\]](https://helm.sh/docs/topics/charts/)

> Tip: You can auto‑generate a starter schema from your `values.yaml`, then refine it:
>
> ```bash
> helm plugin install https://github.com/karuppiah7890/helm-schema-gen
> helm schema-gen values.yaml > values.schema.json
> ```
>
> (Then add descriptions, enums, patterns, and Onyxia extensions.) [\[codeengineered.com\]](https://codeengineered.com/blog/2020/helm-json-schema/), [\[arthurkoziel.com\]](https://www.arthurkoziel.com/validate-helm-chart-values-with-json-schemas/)

***

## 2) Add a `values.schema.json` with Onyxia‑specific hints

Onyxia reads your chart’s schema to:

*   know **which fields to show** in the launch form,
*   apply **types, constraints, defaults**,
*   inject **user-specific defaults** (e.g., S3, Vault, Git info) via custom **`x-onyxia`** extensions. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)

A minimal example (trimmed for brevity):

```json
{
  "$schema": "http://json-schema.org/schema#",
  "type": "object",
  "properties": {
    "image": {
      "type": "object",
      "properties": {
        "repository": { "type": "string", "description": "Container image" },
        "tag": { "type": "string", "description": "Image tag" },
        "pullPolicy": {
          "type": "string",
          "enum": ["IfNotPresent", "Always", "Never"]
        }
      },
      "required": ["repository", "tag"]
    },
    "resources": {
      "type": "object",
      "properties": {
        "requests": {
          "type": "object",
          "properties": {
            "cpu": { "type": "string", "pattern": "^[0-9]+m$" },
            "memory": { "type": "string", "pattern": "^[0-9]+(Mi|Gi)$" }
          }
        }
      },
      "x-onyxia": {
        "useRegionSliderConfig": true
      }
    },
    "git": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "x-onyxia": { "overwriteDefaultWith": "{{ user.git.name }}" }
        },
        "email": {
          "type": "string",
          "format": "email",
          "x-onyxia": { "overwriteDefaultWith": "{{ user.git.email }}" }
        },
        "token": {
          "type": "string",
          "x-onyxia": { "overwriteDefaultWith": "{{ user.git.token }}" }
        }
      }
    },
    "s3": {
      "type": "object",
      "properties": {
        "enabled": { "type": "boolean", "default": true },
        "bucket": {
          "type": "string",
          "x-onyxia": { "overwriteDefaultWith": "{{ project.s3.defaultBucket }}" }
        }
      }
    }
  }
}
```

*   `x-onyxia.useRegionSliderConfig: true` lets Onyxia enforce region-level CPU/RAM/GPU limits and render sliders accordingly.
*   `overwriteDefaultWith` uses **mustache-like** placeholders to pull user or project context (e.g., Git name/email). [\[docs.onyxia.sh\]](https://docs.onyxia.sh/docs.onyxia.sh/v7/catalog-of-services)

> For inspiration, browse the official **interactive services** charts and their schemas (Jupyter, RStudio, VS Code, etc.). They show many reusable schema fragments (S3/Vault/GPU/persistence). [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)

***

## 3) Publish your chart in a Helm repository

The simplest way is GitHub Pages:

1.  Put your chart(s) under `charts/` in a repo.

2.  Package and index:

    ```bash
    helm package charts/my-service -d docs
    helm repo index docs --url https://<your-org>.github.io/<your-repo>/
    ```

3.  Enable GitHub Pages to serve from `/docs`.

4.  Your Helm repo URL will look like:
        https://<your-org>.github.io/<your-repo>/index.yaml

Onyxia can consume **any** Helm repository URL; the official catalogs are built the same way. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services), [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)

***

## 4) Register the repo as a Catalog in Onyxia

As an Onyxia admin, add your repo in the Onyxia configuration (`onyxia.api.catalogs`)—typically via the Onyxia Helm chart’s `values.yaml` (or your platform’s deployment config). Example:

```yaml
onyxia:
  api:
    catalogs:
      - type: "helm"
        id: "my-org-services"
        location: "https://<your-org>.github.io/<your-repo>/"
        name:
          en: "My Org Services"
          es: "Servicios de mi organización"
          fr: "Services de mon organisation"
        status: "PROD"               # or "TEST" (hidden tab, addressable by URL)
        highlightedCharts:
          - "my-service"
        excludedCharts:
          - "experimental-service"
        restrictions:
          - userAttribute:
              key: "groups"
              matches: "data-platform-admins"
        # Optional TLS options:
        # skipTlsVerify: false
        # caFile: "/path/to/ca.crt"
```

*   Each repo becomes a tab in the Service Catalog; each chart becomes a service card.
*   You can **scope visibility** with `restrictions`, highlight cards, or exclude some charts. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services/custom-catalogs), [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)

If you don’t configure any catalogs, Onyxia loads the defaults (Interactive services, Databases, Automation, etc.), but adding yours is the way to expose custom services. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)

***

## 5) Test and iterate

*   **Open the catalog tab**, click your service, confirm the form fields match your schema and defaults. Onyxia renders the form from `values.schema.json` and builds the final values passed to Helm. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)
*   **Check resource sliders/limits** if you used `x-onyxia.useRegionSliderConfig` (these can be defined at region level by the platform admin). [\[docs.onyxia.sh\]](https://docs.onyxia.sh/docs.onyxia.sh/v7/catalog-of-services)
*   **Launch** and ensure your service comes up with the intended ingress/route, persistence, S3/Vault integration, etc. (The official instance is a handy reference for how services look/behave.) [\[datalab.sspcloud.fr\]](https://datalab.sspcloud.fr/)

***

## Practical tips & patterns

*   **Start from a known-good template**: fork the official *interactive services* catalog, then adapt a chart (rename, change images, trim features). This is often faster than starting from scratch and already includes polished schemas for IDEs, GPU, persistence, S3, Vault, etc. [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)
*   **Keep `values.yaml` sane and documented**—then make the schema the “source of truth” for validation and UI documentation (descriptions, enums, patterns). Helm will validate against it on `install/upgrade/lint/template`. [\[helm.sh\]](https://helm.sh/docs/topics/charts/), [\[arthurkoziel.com\]](https://www.arthurkoziel.com/validate-helm-chart-values-with-json-schemas/)
*   **Use per‑group policies**: Onyxia can show/hide catalogs or services by user attributes (e.g., Keycloak groups). Good for gated GPU services. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services/custom-catalogs)
*   **Expose services**: choose between ingress/route and user-hostnames; many official charts include an `ingress` block in schema to control hostnames/class annotations. [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)
*   **Programmatic control**: you can also list catalogs and launch services through the Onyxia API (useful for automation/testing). [\[github.com\]](https://github.com/InseeFrLab/onyxia-api), [\[docs.dive.edito.eu\]](https://docs.dive.edito.eu/articles/integration/interactWithTheServiceAPI.html)

***

## Minimal working example

**Chart layout (extract):**

    my-service/
      Chart.yaml
      values.yaml
      values.schema.json
      templates/
        deployment.yaml
        service.yaml
        ingress.yaml

**`values.yaml` (snippet):**

```yaml
image:
  repository: ghcr.io/my-org/my-service
  tag: "1.0.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: "250m"
    memory: "512Mi"

ingress:
  enabled: true
  hostname: ""   # let Onyxia inject default or user-provided hostname
```

**`values.schema.json`**: include fields and the `x-onyxia` bits as shown earlier, and (optionally) the “ingress” schema modeled after the official charts to let users choose hostnames/class. [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)

***

## Why this works in Onyxia

*   Onyxia loads the catalogs (Helm repos) you configure and displays them as tabs. Each chart becomes a **service card**. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)
*   Opening a service reads the **chart’s JSON Schema** and renders the form; Onyxia **injects defaults** (user profile, S3/Vault, region limits) through `x-onyxia` conventions. [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services), [\[docs.onyxia.sh\]](https://docs.onyxia.sh/docs.onyxia.sh/v7/catalog-of-services)
*   When you click **Launch**, Onyxia calls Helm to install your chart with the final values. [\[github.com\]](https://github.com/InseeFrLab/onyxia-api)

***

## Handy references

*   **Admin doc — Catalog of services** (mental model, defaults, customization, `x-onyxia`, custom catalogs) [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services)
*   **Custom Catalogs** (full example for adding your own repo with name, highlights, exclusions, restrictions, TLS options) [\[docs.onyxia.sh\]](https://docs.onyxia.sh/admin-doc/catalog-of-services/custom-catalogs)
*   **Official interactive services charts** (great examples of schemas and UX that Onyxia renders) [\[github.com\]](https://github.com/InseeFrLab/helm-charts-interactive-services)
*   **Helm chart structure & schema file** (what Helm expects; where `values.schema.json` lives) [\[helm.sh\]](https://helm.sh/docs/topics/charts/)

***
