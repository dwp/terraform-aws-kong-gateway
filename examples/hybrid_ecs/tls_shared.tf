# generate certificates for Kong
resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  validity_period_hours = "12"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  subject {
    common_name = "kong_clustering"
  }

}

resource "tls_private_key" "cert" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "cert" {
  private_key_pem = tls_private_key.cert.private_key_pem

  subject {
    common_name = "kong_clustering"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.cert.cert_request_pem

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = "12"
  allowed_uses = [
  ]

}

resource "aws_ssm_parameter" "cert" {
  name  = format("/%s/%s/ee/selfsigned/crt", var.service, var.environment)
  type  = "SecureString"
  value = tls_locally_signed_cert.cert.cert_pem
}

resource "aws_ssm_parameter" "key" {
  name  = format("/%s/%s/ee/selfsigned/key", var.service, var.environment)
  type  = "SecureString"
  value = tls_private_key.cert.private_key_pem
}
