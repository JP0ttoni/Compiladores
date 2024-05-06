SCANNER := lex
SCANNER_PARAMS := -o output/lex.yy.c src/lexico.l 
PARSER := yacc
PARSER_PARAMS := -d src/sintatico.y -o output/y.tab.c -Wcounterexamples -v

all: compile translate

compile:
		mkdir -p output
		$(SCANNER) $(SCANNER_PARAMS)
		$(PARSER) $(PARSER_PARAMS)
		g++ -o glf output/y.tab.c -ll

run: 	glf
		clear
		compile
		translate

debug:	PARSER_PARAMS += -Wcounterexamples
debug: 	all

translate: glf
		./glf < examples/exemplo.jsm

clean:
	rm -rf output