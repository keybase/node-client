%lex

%%

[ \t\n]+             /* ignore */
[^ \t\n()&|]+        return 'URI';
'&&'                 return 'AND';
'||'                 return 'OR';
'('                  return 'LPAREN';
')'                  return 'RPAREN';
.                    return 'UNHANDLED';
<<EOF>>              return 'EOF';

/lex

%left OR
%left AND

%start expressions

%% /* language grammar */

expressions
    : e EOF { return $1; }
    ;

e
    : e OR e          { $$ = new yy.OR($1, $3); }
    | e AND e         { $$ = new yy.AND($1, $3); }
    | LPAREN e RPAREN { $$ = $2; }
    | URI             { $$ = yy.URI.parse({s : $1, strict : true}); }
    ;
