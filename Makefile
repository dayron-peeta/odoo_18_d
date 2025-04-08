# Cargar variables desde el archivo .env
include .env
export $(shell sed 's/=.*//' .env)

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
ODOO_CONTAINER ?= odoo_18_d-odoo-1
DB_NAME ?= pms
MODULE ?= all
update-odoo-modules:
	@read -p "-----[INPUT] Enter the container name (default: $(ODOO_CONTAINER)): " input; \
	ODOO_CONTAINER=$${input:-$(ODOO_CONTAINER)}; \
	read -p "-----[INPUT] Enter the database name (default: $(DB_NAME)): " input; \
	DB_NAME=$${input:-$(DB_NAME)}; \
	read -p "-----[INPUT] Enter the module to update (default: $(MODULE)): " input; \
	MODULE=$${input:-$(MODULE)}; \
	echo "-----[INFO] Updating module(s) '$$MODULE' in database '$$DB_NAME' inside container '$$ODOO_CONTAINER'..."; \
	docker exec -it $$ODOO_CONTAINER bash -c "/app/sources/dists/odoo/odoo-bin -c /app/odoo.conf -d $$DB_NAME -u $$MODULE --stop-after-init"; \
	echo "-----[SUCCESS] Update completed."

.PHONY: update-odoo-modules

# Inicializar base de datos ------------------------------------------------------------------------------------------------
init-db:
	@echo "🔄 Inicializando la base de datos '$(DB_NAME)' en el contenedor '$(CONTAINER_NAME)' con usuario '$(DB_USER)'..."
	docker exec -it $(CONTAINER_NAME) odoo -i base --db_host=$(DB_HOST) --db_user=$(DB_USER) --db_password=$(DB_PASSWORD) -d $(DB_NAME) --stop-after-init
	@echo "✅ Base de datos '$(DB_NAME)' inicializada correctamente."
.PHONY: init-db