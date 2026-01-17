# Guía de Configuración de Infisical

Este documento describe el proceso completo para configurar Infisical y sus secretos para el proyecto.

## Instalación del Servidor Infisical

### 1. Instalar Infisical en el Bastion

```bash
./scripts/setup-infisical-bastion.sh
```

Esto instalará Infisical en Docker y estará disponible en `http://localhost:8080`.

### 2. Instalar el CLI de Infisical

```bash
./scripts/install-infisical-cli.sh
```

El CLI permite interactuar con Infisical desde la línea de comandos y desde Terragrunt.

## Configuración Inicial en la UI

### 1. Crear Cuenta de Administrador

1. Acceder a http://localhost:8080
2. Hacer clic en "Sign up"
3. Crear la primera cuenta (será el administrador)
4. Verificar el email (en despliegue local, usar mailhog o similar si es necesario)

### 2. Crear Proyectos por Ambiente

Crear un proyecto separado para cada ambiente:

#### Proyecto para DEV

1. Ir a **Projects** → **Create Project**
2. Nombre: `k8s-dev`
3. Descripción: "Secretos para el cluster Kubernetes de desarrollo"
4. Guardar el **Project ID** que aparece en la URL: `proj_xxxxxxxxxxxxxxxxxxxx`

#### Proyecto para STAGING

1. Ir a **Projects** → **Create Project**
2. Nombre: `k8s-staging`
3. Descripción: "Secretos para el cluster Kubernetes de staging"
4. Guardar el **Project ID**

### 3. Configurar Ambientes en Cada Proyecto

Por defecto, Infisical crea los ambientes "dev", "staging" y "prod". Si necesitas crear ambientes personalizados:

1. Ir al proyecto
2. **Project Settings** → **Environments**
3. Crear/editar según sea necesario

## Configuración de Secretos

### 1. Agregar Secretos al Proyecto DEV

1. Seleccionar proyecto `k8s-dev`
2. Seleccionar ambiente "dev" (dropdown arriba a la derecha)
3. Hacer clic en **Add Secret**

#### Secretos Requeridos

| Key | Ejemplo de Valor | Descripción |
|-----|------------------|-------------|
| `SSH_PUBLIC_KEY` | `ssh-rsa AAAAB3Nz...` | Clave pública SSH para cloud-init |

**Cómo obtener el valor:**

```bash
# SSH Public Key
cat ~/.ssh/id_rsa.pub
```

4. Copiar el valor completo
5. Pegar en el campo "Value"
6. Hacer clic en **Save**

### 2. Agregar Secretos al Proyecto STAGING

Repetir el mismo proceso para el proyecto `k8s-staging`, ambiente "staging".

## Generar Service Tokens

Los Service Tokens permiten que Terragrunt acceda a los secretos sin autenticación interactiva.

### 1. Token para DEV

1. Ir al proyecto `k8s-dev`
2. Navegar a: **Project** → **Access Control** → **Service Tokens**
3. Hacer clic en **"Create Service Token"** o **"Add Token"**
4. Configuración:
   - **Name**: `terragrunt-dev`
   - **Environment**: Seleccionar `dev`
   - **Secret Path**: `/` (raíz, acceso a todos los secretos)
   - **Permissions**: `Read` (solo lectura es suficiente para Terragrunt)
   - **Expiration**: `Never` o configurar según política de seguridad (ej: 90 días)
5. Hacer clic en **"Create"** o **"Generate"**
6. **IMPORTANTE**: Copiar el token inmediatamente
   - Formato típico: `st.xxx.yyy.zzz`
   - Solo se muestra UNA vez
   - Guardar temporalmente en un lugar seguro

### 2. Token para STAGING

Repetir el mismo proceso para el proyecto `k8s-staging`:
1. Ir al proyecto `k8s-staging`
2. **Project** → **Access Control** → **Service Tokens**
3. Crear token con nombre `terragrunt-staging` y ambiente `staging`

## Configuración de Variables de Entorno

### 1. Exportar Tokens en el Bastion

```bash
# Service Tokens de Infisical (reemplazar con los valores reales)
export INFISICAL_TOKEN_DEV="st.dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export INFISICAL_TOKEN_STAGING="st.staging_yyyyyyyyyyyyyyyyyyyyyyyyyyyy"

# Project IDs (desde la UI de Infisical)
export INFISICAL_PROJECT_ID_DEV="proj_abc123def456"
export INFISICAL_PROJECT_ID_STAGING="proj_xyz789uvw012"
```

### 2. Hacer Persistentes las Variables (Opcional)

Para que las variables persistan entre sesiones:

```bash
# Agregar al final de ~/.bashrc o ~/.zshrc
cat >> ~/.bashrc << 'EOF'

# Infisical Configuration
export INFISICAL_TOKEN_DEV="st.dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export INFISICAL_TOKEN_STAGING="st.staging_yyyyyyyyyyyyyyyyyyyyyyyyyyyy"
export INFISICAL_PROJECT_ID_DEV="proj_abc123def456"
export INFISICAL_PROJECT_ID_STAGING="proj_xyz789uvw012"
EOF

# Recargar configuración
source ~/.bashrc
```

**Advertencia de Seguridad:** Esta opción es conveniente pero menos segura. En producción, usar:
- Variables secretas del sistema CI/CD
- Credential managers del SO
- Rotación periódica de tokens

## Integración con Terragrunt

Los archivos `terragrunt.hcl` ya están configurados para usar Infisical CLI. Esta sección explica cómo funciona la integración.

### Configuración Actual

Los archivos `terraform/live/dev/k8s-cluster/terragrunt.hcl` y `terraform/live/staging/k8s-cluster/terragrunt.hcl` ya incluyen la integración:

```hcl
# Configuración de secretos
locals {
  # Token desde variable de entorno
  infisical_token = get_env("INFISICAL_TOKEN_DEV", "")

  # Project ID desde variable de entorno
  infisical_project_id = get_env("INFISICAL_PROJECT_ID_DEV", "")

  # Leer secreto desde Infisical con CLI
  ssh_public_key = local.infisical_token != "" ? run_cmd(
    "--terragrunt-quiet",
    "sh", "-c",
    "infisical secrets get SSH_PUBLIC_KEY --projectId=${local.infisical_project_id} --env=dev --token=${local.infisical_token} --silent --plain"
  ) : ""
}

inputs = {
  cloud_init_user_data = templatefile(local.cloud_init_template, {
    ssh_public_key = local.ssh_public_key  # Usa el secreto de Infisical
  })
}
```

### Cómo Funciona

1. **Lectura de Variables de Entorno**: Terragrunt lee `INFISICAL_TOKEN_DEV` y `INFISICAL_PROJECT_ID_DEV`
2. **Condicional con Fallback**: Si el token existe, usa Infisical; si no, usa el archivo local
3. **Ejecución del CLI**: `run_cmd` ejecuta el comando `infisical secrets get` durante el plan/apply
4. **Inyección del Secreto**: El valor se pasa al template de cloud-init


### Añadir Más Secretos (Opcional)

Si necesitas añadir más secretos en el futuro:

```hcl
locals {
  # Leer múltiples secretos
  db_password = local.infisical_token != "" ? run_cmd(
    "--terragrunt-quiet",
    "sh", "-c",
    "infisical secrets get DB_PASSWORD --projectId=${local.infisical_project_id} --env=dev --token=${local.infisical_token} --silent --plain"
  ) : "default_password"

  api_key = local.infisical_token != "" ? run_cmd(
    "--terragrunt-quiet",
    "sh", "-c",
    "infisical secrets get API_KEY --projectId=${local.infisical_project_id} --env=dev --token=${local.infisical_token} --silent --plain"
  ) : "default_key"
}
```

## Verificación de la Configuración

### 1. Probar el CLI con el Token de DEV

```bash
# Verificar que el token funciona
infisical secrets list \
  --projectId="${INFISICAL_PROJECT_ID_DEV}" \
  --env=dev \
  --token="${INFISICAL_TOKEN_DEV}"

# Debería mostrar:
# KEY              VALUE
# SSH_PUBLIC_KEY   ssh-rsa AAAAB3...
```

### 2. Obtener un Secreto Específico

```bash
# Obtener SSH_PUBLIC_KEY
infisical secrets get SSH_PUBLIC_KEY \
  --projectId="${INFISICAL_PROJECT_ID_DEV}" \
  --env=dev \
  --token="${INFISICAL_TOKEN_DEV}" \
  --silent

# Debería mostrar solo el valor del secreto
```

### 3. Probar con Terragrunt

```bash
cd terraform/live/dev/k8s-cluster

# Esto debería funcionar sin errores si todo está configurado
terragrunt plan
```

## Modo Fallback (Sin Infisical)

Si las variables de entorno NO están configuradas, Terragrunt usará el archivo local como fallback:

```hcl
ssh_public_key = local.infisical_token != "" ? run_cmd(...) : file("~/.ssh/id_rsa.pub")
```

Esto permite:
- Trabajar sin Infisical durante desarrollo local
- No bloquear el flujo si Infisical está temporal no disponible
- Facilitar onboarding de nuevos desarrolladores

## Troubleshooting

### Error: "secret not found"

**Causa:** El secreto no existe en Infisical o el nombre es incorrecto

**Solución:**
1. Verificar en la UI que el secreto existe
2. Verificar que el nombre coincide exactamente (case-sensitive)
3. Verificar que estás en el ambiente correcto (dev vs staging)

### Error: "invalid token"

**Causa:** Token expirado, revocado o incorrecto

**Solución:**
1. Generar un nuevo token desde la UI
2. Verificar que la variable de entorno tiene el valor correcto:
   ```bash
   echo $INFISICAL_TOKEN_DEV
   ```
3. Actualizar la variable si es necesario

### Error: "command not found: infisical"

**Causa:** CLI no instalado o no en el PATH

**Solución:**
```bash
# Reinstalar CLI
./scripts/install-infisical-cli.sh

# Verificar PATH
which infisical
```

### Terragrunt usa el fallback en lugar de Infisical

**Causa:** Variables de entorno no configuradas

**Solución:**
```bash
# Verificar que las variables están configuradas
env | grep INFISICAL

# Si no aparece nada, exportarlas de nuevo
export INFISICAL_TOKEN_DEV="st.xxx..."
```

## Siguientes Pasos

1. **Añadir más secretos** según sea necesario (DB passwords, API keys, etc.)
2. **Configurar backups** del directorio `/opt/infisical/data`
3. **Implementar rotación de tokens** cada 90 días
4. **Configurar auditoría** revisando logs en Infisical UI
5. **Documentar** secretos adicionales en este archivo

## Referencias

- [Documentación de Infisical CLI](https://infisical.com/docs/cli/overview)
- [Service Tokens](https://infisical.com/docs/documentation/platform/token)
- [Secrets Management en Terragrunt](../../docs/SECRETS_MANAGEMENT.md)
