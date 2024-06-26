#include <iostream>

using namespace std;

#pragma once
namespace bison {

    vector<string> fatiaString(string str, string del) {
        size_t pos_start = 0, pos_end, delim_len = del.length();
        string token;
        vector<string> res;

        while ((pos_end = str.find(del, pos_start)) != string::npos) {
            token = str.substr (pos_start, pos_end - pos_start);
            pos_start = pos_end + delim_len;
            res.push_back (token);
        }

        res.push_back (str.substr (pos_start));
        return res;
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