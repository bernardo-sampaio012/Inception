-include srcs/.env

LOGIN ?= bsampaio
DATA = /home/$(LOGIN)/data
COMPOSE =  docker compose -f srcs/docker-compose.yml

all: up

up:
	@mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

start:
	@$(COMPOSE) start

stop:
	@$(COMPOSE) stop

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs

clean: down
	@$(COMPOSE) down --rmi all

fclean:
	@$(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA)

re: fclean all

.PHONY: all up down start stop ps logs clean fclean re