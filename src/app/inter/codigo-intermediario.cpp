/* Compilador JSM */

#include <iostream>
#include <string.h>
#include <stdio.h>

#define bool int
#define true 1
#define false 0

using namespace std;

/* Prototipos das Funções Utilitárias */

int calcularTamanhoString(char *str);

/*-=-*/

/* Implementação das funções */

int calcularTamanhoString(char *str) {
    int i = 0;
    while (str[i] != '\0') {
        i++;
    }
    return i;
}