#include <iostream>
#include <string>
#include <sstream>
#include <vector>

using namespace std;

#pragma once
namespace app {

    int varQtd = 0;

    typedef struct {
        string label;
        string tipo;
        string traducao;
    } CurrentType;
    
    class Variavel {
        private:
            string nome;
            string tipo;
        public:
            Variavel(string nome, string tipo) {
                this->nome = nome;
                this->tipo = tipo;
            }

            string getNome() {
                return this->nome;
            }

            string getTipo() {
                return this->tipo;
            }
    }

    string gerarTemporaria(bool temp = false) {
        if (temp) {
            return "t" + to_string(varQtd++);
        }

        return "v" + to_string(varQtd++);
    }

    

    void yyerror(string mensagem, string codigoErro = "Erro de sintaxe") {
        cout << codigoErro << ": " << mensagem << endl;
        exit(1);
    }

}