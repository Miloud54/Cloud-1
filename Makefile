NAME =	inception

SRCS = ./srcs/docker-compose.yml
ENV = ./srcs/.env
DATA_PATH = /home/edidier/data

COMPOSE = docker compose -f $(SRCS) --env-file $(ENV)

all:	setup up

setup:
	@sudo mkdir -p $(DATA_PATH)/wordpress
	@sudo mkdir -p $(DATA_PATH)/mariadb
	@sudo chmod 777 $(DATA_PATH)/wordpress
	@sudo chmod 777 $(DATA_PATH)/mariadb

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -af

re:
	$(COMPOSE) stop
	$(COMPOSE) up -d --build

.PHONY: all setup up down logs ps clean fclean re
