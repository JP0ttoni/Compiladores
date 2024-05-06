#include <iostream>
#include <string>
#include <sstream>
#include <vector>

using namespace std;

#pragma once
namespace app {

    typedef struct {
        string label;
        string tipo;
        string traducao;
    } CurrentType;

    void yyerror(string mensagem, string codigoErro = "Erro de sintaxe") {
        cout << codigoErro << ": " << mensagem << endl;
        exit(1);d
    }

}