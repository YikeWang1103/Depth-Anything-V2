# Handy commands:
# - `make docker-build`: builds DOCKERIMAGE (default: `packnet-sfm:latest`)
PROJECT ?= depth_anything_v2
WORKSPACE ?= /workspaces/$(PROJECT)
# DOCKER_IMAGE ?= 252625084269.dkr.ecr.eu-west-1.amazonaws.com/packnet-sfm:latest
DOCKER_IMAGE ?= depth-anything-v2:latest
CONTAINER_REGISTRY ?= crpi-2gia21gw2a1xso12.cn-shanghai.personal.cr.aliyuncs.com/fusionride
GPU=0
CPUSET ?=  0-25 # Choose from 0-25 (0-12, 13-25), 26-51 (26-38, 39-51), 52-77 (52-64, 65-77), 78-103 (78-90, 91-103)
CONTAINER_NAME ?= depth-anything-v2-${USER}_${GPU}_${CPUSET}
ENV_FILE_PATH ?= ~/dockerenv
# the safe.directory call is needed as docker container access with root and repository is typically created with user permissions
# COMMAND="git config --global --add safe.directory /workspaces/sfm-dest && python scripts/train.py configs/train_fusionride_carnet_low_res.yaml"

SHMSIZE ?= 512g
MEMORY ?= 512g
MEMORYSWAP ?= 0g
WANDB_MODE ?= run
DOCKER_OPTS := \
			--env-file ${ENV_FILE_PATH} \
			--name ${CONTAINER_NAME} \
			--rm -it \
			--shm-size=${SHMSIZE} \
			--cpuset-cpus ${CPUSET} \
			--memory=${MEMORY} \
			--dns 8.8.8.8 \
			--memory-swap=${MEMORYSWAP} \
			--gpus='"'device=${GPU}'"'\
            -e DISPLAY=${DISPLAY} \
			-v /data:/data \
			-v /mnt:/mnt \
			-v /home/efs:/home/efs \
			-v /home/checkpoints:/home/checkpoints \
			-v ~/.cache:/root/.cache \
			-v /tmp:/tmp \
			-v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 \
			-v ${PWD}:${WORKSPACE} \
			-w ${WORKSPACE} \
			--ipc=host \
			--net=host

NGPUS=$(shell nvidia-smi -L | wc -l)



docker-build:
	cp requirements.txt docker/requirements.txt
	cd ./docker && docker build \
		-f Dockerfile \
		-t ${DOCKER_IMAGE} .

docker-run-interactive:
	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE} bash


# docker-run-without-build:
# 	docker run ${DOCKER_OPTS} ${DOCKER_IMAGE} bash -c ${COMMAND}

docker-enter:
	docker container start ${CONTAINER_NAME}
	docker exec -it ${CONTAINER_NAME} /bin/bash

docker-pull:
	docker pull ${CONTAINER_REGISTRY}/${DOCKER_IMAGE}
	docker image tag ${CONTAINER_REGISTRY}/${DOCKER_IMAGE} ${DOCKER_IMAGE}

docker-push:
	docker image tag ${DOCKER_IMAGE} ${CONTAINER_REGISTRY}/${DOCKER_IMAGE}
	docker push ${CONTAINER_REGISTRY}/${DOCKER_IMAGE}

	
