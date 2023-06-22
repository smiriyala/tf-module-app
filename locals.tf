locals {
    dns_word = var.env == "prod" ? "www" : var.env
    dns_name = var.component == "frontend" ? "${local.dns_word}.${var.dns_domain}" : "${var.component}-${var.dns_domain}"

}