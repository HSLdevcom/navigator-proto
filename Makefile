JS_DEST		:= js/
COFFEE_ARGS	:= -o $(JS_DEST)

compile:
	coffee $(COFFEE_ARGS) --compile src/*.coffee

watch:
	coffee $(COFFE_ARGS) --compile --watch src/*.coffee
