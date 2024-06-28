%{
#include <string>
%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+

INTEIRO ({DIGITO})+
REAL (((({DIGITO}+)|({DIGITO}*\.{DIGITO}+))([eE][-+]?{DIGITO}+)?))

CHAR \'({LETRA}|{INTEIRO})\'
ID {LETRA}({LETRA}|{INTEIRO})*

TIPOS "int"|"float"|"bool"|"char"|"string"

%%

{DELIM} 	    { /* Ignorar espaços em branco*/            }
"\n"		    {                                           }
  
"main"		    { return TK_MAIN;                           }
  
"var"           { return TK_VAR;                            }
"as"            { return TK_AS;                             }

"print"         { return TK_PRINT;                          }
"println"       { return TK_PRINTLN;                        }

"&&"            { return TK_AND;                            }
"and"           { return TK_AND;                            }
"||"            { return TK_OR;                             }
"or"            { return TK_OR;                             }
"!"             { return TK_NOT;                            }
"not"           { return TK_NOT;                            }

"=="            { return TK_IGUAL;                          }
"!="            { return TK_DIFERENTE;                      }
">"             { return TK_MAIOR;                          }
"<"             { return TK_MENOR;                          }
">="            { return TK_MAIOR_IGUAL;                    }
"<="            { return TK_MENOR_IGUAL;                    }

{TIPOS}         { yylval.label = yytext; return TK_TIPO;    }

"--"            { return TK_MENOS_MENOS;                    }
"++"            { return TK_MAIS_MAIS;                      }
"//"            { return TK_DIV;                            }
[+\-*/|\"]      { return *yytext;                           }
[(){}[\]]       { return *yytext;                           }
[;,~:=%_]       { return *yytext;                           }

{INTEIRO}		{ yylval.label = yytext; return TK_INTEIRO; }
{REAL}          { yylval.label = yytext; return TK_REAL;    }

"true"          { yylval.label = "true"; return TK_TRUE;    }
"false"         { yylval.label = "false"; return TK_FALSE;  }

{ID}		    { yylval.label = yytext; return TK_ID;       }
    
.			    { *yytext;                                   }
    
%%