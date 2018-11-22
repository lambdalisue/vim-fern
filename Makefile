LANG  := C
CYAN  := \033[36m
GREEN := \033[32m
RESET := \033[0m
TAG   := latest
VIM   := vim
ARGS  :=
IMAGE := lambdalisue/${VIM}-themis

ifeq (${VIM},neovim)
    VIMC := nvim
else
    VIMC := ${VIM}
endif

# http://postd.cc/auto-documented-makefile/
.DEFAULT_GOAL := help
.PHONY: help
help: ## Show this help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "${CYAN}%-30s${RESET} %s\n", $$1, $$2}'

.PHONY: version
version: version-vim version-themis ## Show Vim/vim-themis version in a docker image

.PHONY: version-vim
version-vim: ## Show Vim version in a docker image
	@docker run --rm --entrypoint= \
	    -it ${IMAGE}:${TAG} \
	    /usr/local/bin/${VIMC} --version

.PHONY: version-themis
version-themis: ## Show vim-themis version in a docker image
	@docker run --rm -it ${IMAGE}:${TAG} --version

.PHONY: lint
lint: ## Run lint by vim-vint and misspell
	@echo "${GREEN}Running lint by vim-vint and misspell${RESET}"
	@vint .
	@misspell .

.PHONY: test
test: ## Run unittests by using a docker image
	@echo "${GREEN}Running unittests by using a docker image (${IMAGE}:${TAG})${RESET}"
	@docker run --rm --volume ${PWD}:/mnt/volume ${ARGS} -it ${IMAGE}:${TAG}

.PHONY: helptags
helptags: ## Build helptags by using a docker image
	@echo "${GREEN}Building helptags by using a docker image (${IMAGE}:${TAG})${RESET}"
	@docker run --rm --entrypoint= \
	    --volume ${PWD}:/mnt/volume \
	    -it ${IMAGE}:${TAG} \
	    /usr/local/bin/${VIMC} \
	    --cmd "try | helptags doc/ | catch | cquit | endtry" \
	    --cmd quit
