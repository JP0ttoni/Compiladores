SCANNER := lex
SCANNER_PARAMS := -o output/lex.yy.c src/lexico.l 
PARSER := yacc
PARSER_PARAMS := -d src/sintatico.y -o output/y.tab.c -Wcounterexamples -v

all: compile
	./output/compiler.exe --debug --simplify < examples/exemplo.jsm

compile:
		mkdir -p output
		$(SCANNER) $(SCANNER_PARAMS)
		$(PARSER) $(PARSER_PARAMS)
		g++ -o output/compiler.exe output/y.tab.c -ll

run: 	clean compile
	./output/compiler.exe < examples/exemplo.jsm > output/exemplo.c
	g++ -o output/exemplo.exe output/exemplo.c
	./output/exemplo.exe

debug: compile
	./output/compiler.exe < examples/exemplo.jsm

clean:
	rm -rf output