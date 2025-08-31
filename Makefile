# Cargar variables desde el archivo .env
include .env
export $(shell sed 's/=.*//' .env)

# Variables por defecto
ODOO_CONTAINER ?= odoo_18_d-odoo-1
POSTGRES_CONTAINER ?= odoo_18_d-postgres-1
DB_NAME = pms
DB_USER ?= odoo18
DB_PASSWORD ?= odoo18
DB_HOST ?= postgres

# Iniciar sesión en wsl -----------------------------------------------------------------------------------------------
login-wsl:
	wsl -d $(WSL_DISTRIBUTION) -u $(WSL_USER) 
	#type exit to close session
.PHONY: login-wsl 

# Detener distribución wsl -----------------------------------------------------------------------------------------------
stop-wsl-distribution:
	wsl --terminate $(WSL_DISTRIBUTION) 
	#detiene completamente la distribución de WSL
.PHONY: stop-wsl-distribution

# Deshabilitar wsl -----------------------------------------------------------------------------------------------
disable-wsl:
	wsl --shutdown 
	#detiene todas las instancias de WSL
.PHONY: disable-wsl

# -----------------------------------------------------------------------------------------------
CONTAINER_NAME_OR_ID ?= odoo_18_d-odoo-1
open_terminal_inside_container:
	docker exec -it $(CONTAINER_NAME_OR_ID) bash
.PHONY: open_terminal_inside_container
#create_module_template
#debes ejecutar desde la terminal dentro del contenedor
#utiliza cd para moverte dentro del contenedor EJ:cd /mnt/extra-addons
#odoo scaffold NEW_MODULE_NAME 



# Actualizar módulos de una bd Odoo ----------------------------------------------------------------------------------------------
MODULE_TO_UPDATE = faq_ms

update-odoo-modules:
	@read -p "-----[INPUT] Enter the container name (default: $(ODOO_CONTAINER)): " input; \
	ODOO_CONTAINER=$${input:-$(ODOO_CONTAINER)}; \
	read -p "-----[INPUT] Enter the database name (default: $(DB_NAME)): " input; \
	DB_NAME=$${input:-$(DB_NAME)}; \
	read -p "-----[INPUT] Enter the module to update (default: $(MODULE_TO_UPDATE)): " input; \
	MODULE_TO_UPDATE=$${input:-$(MODULE_TO_UPDATE)}; \
	echo "-----[INFO] Updating module(s) '$$MODULE_TO_UPDATE' in database '$$DB_NAME' inside container '$$ODOO_CONTAINER'..."; \
	if docker exec -it $$ODOO_CONTAINER bash -c "/usr/bin/odoo -c /etc/odoo/odoo.conf -d $$DB_NAME -u $$MODULE_TO_UPDATE --stop-after-init"; then \
		echo "-----[SUCCESS] Update completed."; \
	else \
		echo "-----[ERROR] Update failed!"; \
		exit 1; \
	fi

.PHONY: update-odoo-modules

# Inicializar base de datos ------------------------------------------------------------------------------------------------
init-db:
	@echo "🔄 Inicializando la base de datos '$(DB_NAME)' en el contenedor '$(ODOO_CONTAINER)' con usuario '$(DB_USER)'..."
	docker exec -it $(ODOO_CONTAINER) /usr/bin/odoo -c /etc/odoo/odoo.conf -i base -d $(DB_NAME) --stop-after-init
	@echo "✅ Base de datos '$(DB_NAME)' inicializada correctamente."
.PHONY: init-db

# Ejecutar Docker Compose
docker-up:
	docker-compose up -d
	@echo "✅ Containers started successfully"

.PHONY: docker-up

docker-down:
	docker-compose down
	@echo "✅ Containers stopped successfully"

.PHONY: docker-down

docker-restart:
	docker-compose restart
	@echo "✅ Containers restarted successfully"

.PHONY: docker-restart

# Ver logs de Odoo
logs-odoo:
	docker-compose logs odoo -f

.PHONY: logs-odoo

# Ver logs de PostgreSQL
logs-postgres:
	docker-compose logs postgres -f

.PHONY: logs-postgres

# Acceder a la terminal de Odoo
bash-odoo:
	docker exec -it $(ODOO_CONTAINER) bash

.PHONY: bash-odoo

# Acceder a la terminal de PostgreSQL
bash-postgres:
	docker exec -it $(POSTGRES_CONTAINER) bash

.PHONY: bash-postgres

# Acceder a la base de datos con psql
psql:
	docker exec -it $(POSTGRES_CONTAINER) psql -U $(DB_USER) $(DB_NAME)

.PHONY: psql

# Crear un nuevo módulo (ejecutar desde dentro del contenedor)
create-module:
	@read -p "-----[INPUT] Enter module name: " MODULE_NAME; \
	docker exec -it $(ODOO_CONTAINER) bash -c "cd /mnt/extra-addons && odoo scaffold $$MODULE_NAME ."; \
	echo "-----[SUCCESS] Module '$$MODULE_NAME' created in /mnt/extra-addons"

.PHONY: create-module

# Instalar módulo  Odoo ----------------------------------------------------------------------------------------------
MODULE_NAME = contacts_pms
install-odoo-module:
	@read -p "-----[INPUT] Enter the container name (default: $(ODOO_CONTAINER)): " input; \
	ODOO_CONTAINER=$${input:-$(ODOO_CONTAINER)}; \
	read -p "-----[INPUT] Enter the database name (default: $(DB_NAME)): " input; \
	DB_NAME=$${input:-$(DB_NAME)}; \
	read -p "-----[INPUT] Enter the module to uninstall (default: $(MODULE_NAME)): " input; \
	MODULE_NAME=$${input:-$(MODULE_NAME)}; \
	if [ -z "$$MODULE_NAME" ]; then \
		echo "-----[ERROR] Module name is required"; \
		exit 1; \
	fi; \
	echo "-----[WARNING] You are about to install module '$$MODULE_NAME' in database '$$DB_NAME'"; \
	read -p "-----[CONFIRM] Are you sure? (y/N): " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "-----[INFO] Operation cancelled"; \
		exit 0; \
	fi; \
	echo "-----[INFO] Installing module '$$MODULE_NAME' from database '$$DB_NAME' inside container '$$ODOO_CONTAINER'..."; \
	docker exec -it $$ODOO_CONTAINER bash -c "/usr/bin/odoo -c /etc/odoo/odoo.conf -d $$DB_NAME --init $$MODULE_NAME --stop-after-init"; \
	echo "-----[SUCCESS] Install completed."

.PHONY: install-odoo-module





# Backup de la base de datos
backup-db:
	@echo "💾 Creating backup of database '$(DB_NAME)'..."
	docker exec -it $(POSTGRES_CONTAINER) pg_dump -U $(DB_USER) $(DB_NAME) > backup_$(DB_NAME)_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup completed: backup_$(DB_NAME)_$(shell date +%Y%m%d_%H%M%S).sql"

.PHONY: backup-db

# Listar módulos instalados ----------------------------------------------------------------------------------------------
list-installed-modules:
	@read -p "-----[INPUT] Enter the container name (default: $(ODOO_CONTAINER)): " input; \
	ODOO_CONTAINER=$${input:-$(ODOO_CONTAINER)}; \
	read -p "-----[INPUT] Enter the database name (default: $(DB_NAME)): " input; \
	DB_NAME=$${input:-$(DB_NAME)}; \
	echo "-----[INFO] Listing installed modules in database '$$DB_NAME'..."; \
	docker exec -i $$ODOO_CONTAINER bash -c "printf 'modules = env[\"ir.module.module\"].search([(\"state\", \"=\", \"installed\")])\nfor module in modules:\n    print(f\"{module.name}: {module.state}\")\nexit()\n' | odoo shell -c /etc/odoo/odoo.conf -d $$DB_NAME --no-http"

.PHONY: list-installed-modules

