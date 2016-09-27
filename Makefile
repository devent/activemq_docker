REPOSITORY := erwinnttdata
NAME := activemq
VERSION ?= 5.14.0_007

build: _build ##@targets Builds the docker image.

rebuild: _rebuild ##@targets Builds the docker image anew.

clean: _clean ##@targets Removes the docker image.

deploy: _deploy ##@targets Deploys the docker image to the repository.

include Makefile.help
include Makefile.functions
include Makefile.image

.PHONY +: build rebuild clean deploy
