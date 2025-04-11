
# Inspecting the Source Code of the Odoo Container from the Host

## 1. Create the Folder Structure on Your Host Machine

```bash
mkdir -p odoo-source/odoo/addons
```

## 2. Copy the Original Source Code from the Container

To copy **all addons**:

```bash
docker cp <container_name>:/usr/lib/python3/dist-packages/odoo/addons ./odoo-source/odoo/
```

To copy a **specific addon**, for example `website`:

```bash
docker cp <container_name>:/usr/lib/python3/dist-packages/odoo/addons/website ./odoo-source/odoo/
```

Replace `<container_name>` with your actual container name, for example: `odoo_18_d-odoo-1`.

To verify the path to the `addons` directory inside the container, run:

```bash
find / -type d -name "addons" 2>/dev/null
```

This will return the absolute paths of all directories named `addons`.

To list the contents of the folder:

```bash
ls /usr/lib/python3/dist-packages/odoo/addons
```

To list only folders containing "web" in the name:

```bash
ls /usr/lib/python3/dist-packages/odoo/addons | grep web
```

---

## (Optional) Mount the Source Code as a Volume

> Only do this if you need to **modify** Odoo’s source code.  
> **This is not required for inspection purposes only.**

Edit your `docker-compose.yml` like this:

```yaml
services:
  odoo:
    image: odoo:18
    volumes:
      - ./my-addons:/mnt/extra-addons
      - ./odoo-source/odoo/addons:/usr/lib/python3/dist-packages/odoo/addons
```

> Docker does **not** permanently modify files inside the base image when you use volumes.  
> If the volume is deleted, Docker stops overwriting the target path and reverts to the original content from the `odoo:18` image.

---

## (Only if You Used Volumes) Restart Docker

```bash
docker-compose down
docker-compose up -d
```

---

## Result

You’ll be able to browse the Odoo source code inside:

```
odoo-source/odoo/addons
```
