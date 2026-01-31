output "secrets" {
  description = "Mapa de secretos persistentes: nombre -> valor"
  value       = local.secrets_map
  sensitive   = true
}
