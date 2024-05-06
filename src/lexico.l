%{
#include <string>
%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*

%%

"\n"		    { return EOL;                               }
  
{DELIM} 	    {                                           }
  
"main"		    { return TK_MAIN;                           }
  
"int"		    { return TK_TIPO_INT;                       } 
  
[(){}[\];,.]    { return *yytext;                           }
    
"--"            { return TK_MINUS_MINUS;                    }
[+\-*/%]        { return *yytext;                           }
    
"="		        { return '=';                               }
"'"             { return '\'';                              }
    
[<>]            { return *yytext;                           }
"<="            { return TK_MENOR_IGUAL;                    }
">="            { return TK_MAIOR_IGUAL;                    }
"=="            { return TK_EQUAL;                          }
"!="            { return TK_DIFERENT;                       }
                       
"&&"            { return TK_ELOG;                           }
"||"            { return TK_OR;                             }
"!"             { return TK_NEGATIVE;                       }
    
    
{NUM}		    { yylval.label = yytext; return TK_NUM;     }
{ID}		    { yylval.label = yytext; return TK_ID;      }
    
.			    { *yytext;                                  }
    
%%