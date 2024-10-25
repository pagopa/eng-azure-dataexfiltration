locals {
  project = "${var.prefix}${random_id.unique.hex}-${var.env_short}-${var.location_short}"
}
