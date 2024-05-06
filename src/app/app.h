#include <string>
#include <vector>

#include "bison.h"

using namespace bison;

#pragma once
namespace app {

    int varQtd = 1;

    typedef struct {
        string label;
        string tipo;
        string traducao;
    } CurrentType;

    class Variavel {
        private:
            string nome;
            string apelido;
            string tipo;
        public:
            Variavel(string nome, string apelido, string tipo) {
                this->nome = nome;
                this->apelido = apelido;
                this->tipo = tipo;
            }

            string getNome() {
                return this->nome;
            }

            string getApelido() {
                return this->apelido;
            }

            string getTipo() {
                return this->tipo;
            }
    };

    vector<Variavel> tabelaSimbolos;

    void iniciarCompilador(string traducaoGeral) {

        string traducao = "/*Compilador JSM*/\n"
                "#include <iostream>\n"
                "#include<string.h>\n"
                "#include<stdio.h>\n"
                "#define bool int\n"
                "#define true 1\n"
                "#define false 0\n\n"
                "int main(void) {\n";
        
        string codigo = "";
            
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            codigo += tabelaSimbolos[i].getTipo() + " " + tabelaSimbolos[i].getNome() + ";\n";
        }

        codigo += "\n" + traducaoGeral;

        traducao += formataCodigo(codigo);
                        
        traducao += "\treturn 0;\n}";

        cout << traducao << endl;
    }


    Variavel criarVariavel(string nome, string apelido, string tipo, bool temporaria = false) {
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            if (tabelaSimbolos[i].getApelido() == apelido) {
                yyerror("Variável " + nome + " já foi declarada");
            }
        }

        string apelidoEfetivo = temporaria ? "§" + apelido : apelido;

        Variavel variavel = Variavel(nome, apelidoEfetivo, tipo);
        tabelaSimbolos.push_back(variavel);
        return variavel;
    }

    Variavel* buscarVariavel(string apelido) {
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            if (tabelaSimbolos[i].getApelido() == apelido) {
                return &tabelaSimbolos[i];
            }
        }

        return NULL;
    }
    
    string gerarTemporaria(bool temp = true) {
        if (temp) {
            return "t" + to_string(varQtd++);
        }

        return "v" + to_string(varQtd++);
    }

}