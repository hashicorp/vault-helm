path "sys/mounts" {
  capabilities = ["read"]
}

path "secret/*" {
  capabilities = ["read"]
}