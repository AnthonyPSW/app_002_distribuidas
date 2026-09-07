# Frontend

Carpeta reservada para el cliente Flutter que consume la API del backend.

## Datos que necesita el cliente

| Dato | Valor |
|---|---|
| URL base | `http://100.99.13.87:5086` |
| Prefijo de la API | `/api/medicity/distribuida` |
| CORS | Abierto, política `PermitirFlutter` |
| Documentación interactiva | `http://100.99.13.87:5086/swagger` |

Use la IP de Tailscale, nunca `localhost`: el backend se ejecuta en la máquina
del Sitio A.

## Endpoints disponibles

Los 7 endpoints de la entrega y los endpoints de consulta adicionales están
descritos en el `README.md` de la raíz, sección 10. Los ejemplos de petición
listos para probar están en `Backend/app_02.http`.

## Antes de empezar

1. El backend debe estar ejecutándose en el Sitio A.
2. `LS_SITIO_B` debe responder.
3. Los scripts de `Database/` deben estar aplicados en `MEDICITY_A`.
