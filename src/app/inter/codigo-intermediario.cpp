/* Compilador JSM */

#include <iostream>
#include <string.h>
#include <stdio.h>

#define bool int
#define true 1
#define false 0

using namespace std;

/* Prototipos das Funções Utilitárias */

typedef struct {
    char* str;
    int tamanho;
} String;

int calcularTamanhoString(char *str);
String concatenarString(String s1, String s2);
String copiarString(String str);
int igualdadeStrings(String s1, String s2);

String intToString(int n);
String floatToString(float n);
String boolToString(bool b);
String charToString(char c);

String lerEntrada();

/*-=-*/

/* Implementação das funções */

int calcularTamanhoString(char *str) {
    int i = 0;
    int flag;

inicioWhile:
    flag = str[i] != '\0';
    if (!flag) goto fimWhile;
    i++;
    goto inicioWhile;
fimWhile:

    return i;
}

String concatenarString(String s1, String s2) {
    int tamanhoReal;
    tamanhoReal = s1.tamanho + s2.tamanho;

    String result;

    result.tamanho = tamanhoReal;

    int indice;
    int indiceAtual;

    int flag;

    indice = 0;
    indiceAtual = 0;

inicioWhile:
    flag = indice < s1.tamanho;
    if (!flag) goto fimWhile;
    result.str[indiceAtual] = s1.str[indice];
    indice++;
    indiceAtual++;
    goto inicioWhile;
fimWhile:

    indice = 0;

inicioWhile2:
    flag = indice < s2.tamanho;
    if (!flag) goto fimWhile2;
    result.str[indiceAtual] = s2.str[indice];
    indice++;
    indiceAtual++;
    goto inicioWhile2;
fimWhile2:

    return result;
}

String copiarString(String str) {
    int tamanho;

    tamanho = str.tamanho;

    String string;

    string.str = (char*) malloc(tamanho);
    string.tamanho = tamanho;

    int index = 0;
    int whileFlag;
    
inicioWhile:
    whileFlag = index < tamanho;
    if (!whileFlag) goto fimWhile;
    string.str[index] = str.str[index];
    index++;
    goto inicioWhile;
fimWhile:

    return string;
}

int igualdadeStrings(String s1, String s2) {
    int ifFlag;

    ifFlag = s1.tamanho == s2.tamanho;

    if (!ifFlag) goto retornoFalso;

    int index;
    int whileFlag;

    index = 0;

inicioWhile:
    whileFlag = index < s1.tamanho;
    if (!whileFlag) goto fimWhile;
    ifFlag = s1.str[index] == s2.str[index];
    if (!ifFlag) goto retornoFalso;
    index++;
    goto inicioWhile;
fimWhile:
    
    return true;

retornoFalso:
    return false;
}   

String intToString(int n) {
    String string;

    string.str = (char*) malloc(12);
    sprintf(string.str, "%d", n);
    string.tamanho = calcularTamanhoString(string.str);

    return string;
}

String floatToString(float n) {
    String string;

    string.str = (char*) malloc(12);
    sprintf(string.str, "%f", n);
    string.tamanho = calcularTamanhoString(string.str);

    return string;
}

String boolToString(bool b) {
    String string;
    int flag;

    flag = b != 0;
    if (!flag) goto falseLabel;
    string.str = (char*) malloc(4);
    string.tamanho = 4;

    string.str[0] = 't';
    string.str[1] = 'r';
    string.str[2] = 'u';
    string.str[3] = 'e';

    goto fimIf;
falseLabel:
    string.str = (char*) malloc(5);
    string.tamanho = 5;

    string.str[0] = 'f';
    string.str[1] = 'a';
    string.str[2] = 'l';
    string.str[3] = 's';
    string.str[4] = 'e';
fimIf:

    return string;
}

String charToString(char c) {
    String string;

    string.str = (char*) malloc(1);
    string.str[0] = c;
    string.tamanho = 1;

    return string;
}

// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
String lerEntrada() {
    int tamanho;
    int capacidade;
    char caractere;

    int whileFlag;
    int ifFlag;

    int t1;

    tamanho = 0;
    capacidade = 12;
    caractere = 0;
    char* charPtr = (char*) malloc(capacidade);

iniciarWhile:
    whileFlag = cin.get(caractere) && caractere != '\n';
    if (!whileFlag) goto fimWhile;

    t1 = tamanho + 1;
    ifFlag = t1 >= capacidade;
    if (!ifFlag) goto fimIf;
    capacidade = capacidade * 2;
    charPtr = (char*) realloc(charPtr, capacidade);
fimIf:
    charPtr[tamanho] = caractere;
    tamanho++;
    goto iniciarWhile;
fimWhile:

    charPtr[tamanho] = '\0';

    String *string;

    string = (String*) malloc(sizeof(String));
    string->str = charPtr;

    tamanho--;

    string->tamanho = tamanho;

    return *string;
}