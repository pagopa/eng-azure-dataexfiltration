locals {
  project     = "${var.prefix}-${var.env_short}-${var.location_short}-${var.domain}"
  old_project = "dex-${var.env_short}-${var.location_short}-${var.domain}"
}