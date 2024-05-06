#include <iostream>

using namespace std;

#pragma once
namespace bison {

    vector<string> fatiaString(string str, string del) {
        vector<string> v;
        int end = str.find(del); 

        while (end != -1) {
            v.push_back(str.substr(0, end));
            str.erase(str.begin(), str.begin() + end + 1);
            end = str.find(del);
        }

        return v;
    }

    string formataCodigo(string code) {
        vector<string> lines = fatiaString(code, "\n");
        string identedCode = "";

        for (int i = 0; i < lines.size(); i++) {
            identedCode += "\t" + lines[i] + "\n";
        }

        return identedCode;
    }

    void yyerror(string mensagem, string codigoErro = "Erro de sintaxe") {
        cout << codigoErro << ": " << mensagem << endl;
        exit(1);
    }

}