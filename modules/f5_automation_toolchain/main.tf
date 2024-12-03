variable "type" {
  description = "The type of automation toolchain (e.g., as3, do, cf)."
}

variable "release_version" {
  description = "The version of the release to fetch."
}

# Map types to their respective URLs
locals {
  api_url = {
    as3 = "https://api.github.com/repos/F5Networks/f5-appsvcs-extension/releases"
    do  = "https://api.github.com/repos/F5Networks/f5-declarative-onboarding/releases"
    cf  = "https://api.github.com/repos/F5Networks/f5-cloud-failover-extension/releases"
  }
  selected_api_url = local.api_url[var.type]
}

data "http" "releases" {
  url = local.selected_api_url
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  release_data  = jsondecode(data.http.releases.response_body)
  release       = [for release in local.release_data : release if release.tag_name == "v${var.release_version}"][0]
  hash_asset    = [for asset in local.release.assets : asset if can(regex(".rpm.sha256$", asset.name))][0]
}

data "http" "hash" {
  url = local.hash_asset.browser_download_url
}

locals {
  sha256_value = regex("^[a-f0-9]{64}", trimspace(data.http.hash.response_body))
}

output "sha256_checksum" {
  value = local.sha256_value
}
