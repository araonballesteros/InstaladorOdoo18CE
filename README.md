# Instalador Odoo 18 CE

Este repositorio contiene un script en bash para instalar **Odoo 18 Community Edition** en un entorno de desarrollo basado en Ubuntu 22.04.2.

El instalador configura PostgreSQL, crea el usuario `odoo18` y descarga el código fuente de Odoo. No se incluyen certificados ni acceso HTTPS.

## Uso

Ejecuta el script como usuario con privilegios `sudo`:

```bash
bash instalador_odoo18.sh
```

El servicio se instalará para ejecutarse como `odoo18` y quedará disponible en el puerto por defecto de Odoo.
