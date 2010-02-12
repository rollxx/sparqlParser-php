/*
 * Sparql 1.0 grammar
 *
*/

grammar Erfurt_Sparql_Sparql10 ;


options {
  language = Php;
//  k = 1;
//  memoize = true;
}

//import Tokens ;

@header{

/**
 * Erfurt Sparql Query2 - Var.
 * 
 * @package    erfurt
 * @subpackage Parser
 * @author     Rolland Brunec
 * @copyright  Copyright (c) 2009, {@link http://aksw.org AKSW}
 * @license    http://opensource.org/licenses/gpl-license.php GNU General Public License (GPL)
 * @version    \$Id\$
 */

require_once 'Erfurt/Sparql/Query2/structural-Interfaces.php';
require_once 'Erfurt/Sparql/Query2/ElementHelper.php';
require_once 'Erfurt/Sparql/Query2/ContainerHelper.php';
require_once 'Erfurt/Sparql/Query2/Constraint.php';
require_once 'Erfurt/Sparql/Query2/IriRef.php';
require_once 'Erfurt/Sparql/Query2/OrderClause.php';
require_once 'Erfurt/Sparql/Query2/GroupGraphPattern.php';
require_once 'Erfurt/Sparql/Query2/GraphClause.php';
require_once 'Erfurt/Sparql/Query2.php';
}




@members{
private \$_q = null;
}


// $<Parser

/* sparql 1.0 r1 */
start returns [$value]
@init {\$this->_q = new Erfurt_Sparql_Query2();}
    : prologue ( 
        selectQuery
        | constructQuery 
        | describeQuery 
        | askQuery 
        ) EOF {\$value = \$this->_q;}
    ;

/* sparql 1.0 r2 */
prologue
    : baseDecl? prefixDecl*
    ;

/* sparql 1.0 r3 */
baseDecl
    : BASE iriRef {\$this->_q->setBase($iriRef.value);}
    ;

/* sparql 1.0 r4 */
prefixDecl
@init{require_once 'Erfurt/Sparql/Query2/Prefix.php';}
    : PREFIX PNAME_NS iriRef {\$this->_q->addPrefix(new Erfurt_Sparql_Query2_Prefix($PNAME_NS.text, $iriRef.value));}
    ;

/* sparql 1.0 r5 */
selectQuery
    : SELECT ( DISTINCT {\$this->_q->setDistinct(true);}
        | REDUCED {\$this->_q->setReduced(true);}
        )? ( variable+ | ASTERISK ) datasetClause* whereClause solutionModifier 
    ;

/* sparql 1.0 r6 */
constructQuery
    : CONSTRUCT constructTemplate datasetClause* whereClause solutionModifier
    ;

/* sparql 1.0 r7 */
describeQuery
    : DESCRIBE ( varOrIRIref+ | ASTERISK ) datasetClause* whereClause? solutionModifier
    ;

/* sparql 1.0 r8 */
askQuery
    : ASK datasetClause* whereClause {\$this->_q->setQueryType($ASK.text);}
    ;

/* sparql 1.0 r9 */
datasetClause
    : FROM ( defaultGraphClause {\$this->_q->addFrom($defaultGraphClause.value);}
        | namedGraphClause {\$this->_q->addFrom($namedGraphClause.value, true);}
        )
    ;

/* sparql 1.0 r10 */
defaultGraphClause returns [$value]
    : sourceSelector {\$value = $sourceSelector.value;}
    ;

/* sparql 1.0 r11 */
namedGraphClause returns [$value]
    : NAMED sourceSelector {\$value = $sourceSelector.value;}
    ;

/* sparql 1.0 r12 */
sourceSelector returns [$value]
    : iriRef {\$value = $iriRef.value;}
    ;

/* sparql 1.0 r13 */
whereClause
    : WHERE? groupGraphPattern {\$this->_q->setWhere($groupGraphPattern.value);}
    ;

/* sparql 1.0 r14 */
solutionModifier
    : orderClause? limitOffsetClauses?
    ;
/* sparql 1.0 r15 */
limitOffsetClauses
    : limitClause offsetClause? 
    | offsetClause limitClause?
    ;

/* sparql 1.0 r16 */
orderClause
    : ORDER BY orderCondition+
    ;

/* sparql 1.0 r17 */
orderCondition
    : ( ( o=ASC | o=DESC ) brackettedExpression ) {\$this->_q->getOrder()->add($brackettedExpression.value, $o.text);}
    | ( v=constraint | v=variable) {\$this->_q->getOrder()->add($v.value);}
    ;

/* sparql 1.0 r18 */
limitClause
    : LIMIT INTEGER {\$this->_q->setLimit($INTEGER.text);}
    ;

/* sparql 1.0 r19 */
offsetClause
    : OFFSET INTEGER {\$this->_q->setOffset($INTEGER.text);}
    ;

/* sparql 1.0 r20 */
groupGraphPattern returns [$value]
@init{
require_once('Erfurt/Sparql/Query2/GroupGraphPattern.php');
\$value = new Erfurt_Sparql_Query2_GroupGraphPattern();
}
	: OPEN_CURLY_BRACE (t1=triplesBlock {\$value ->addElements($t1.value);})?
	( ( v=graphPatternNotTriples | v=filter ) {\$value ->addElement($v.value);}
            DOT? (t2=triplesBlock {\$value ->addElements($t2.value);})? )* CLOSE_CURLY_BRACE
    ;

/* sparql 1.0 r21 */
triplesBlock returns [$value]
@init{
\$value = array();
}
    : triplesSameSubject {\$value[]=$triplesSameSubject.value;} ( DOT (t=triplesBlock {\$value = array_merge(\$value, $t.value);})? )? 
    ;

/* sparql 1.0 r22 */
graphPatternNotTriples returns [$value]
@after{\$value = \$v;}
    : v=optionalGraphPattern {\$v=$v.value;}
    | v=groupOrUnionGraphPattern {\$v=$v.value;}
    | v=graphGraphPattern {\$v=$v.value;}
    ;

/* sparql 1.0 r23 */
optionalGraphPattern returns [$value]
@init{require_once('Erfurt/Sparql/Query2/OptionalGraphPattern.php');}
    : OPTIONAL groupGraphPattern {\$value = new Erfurt_Sparql_Query2_OptionalGraphPattern(); \$value->addElement($groupGraphPattern.value);}
    ;

/* sparql 1.0 r24 */
graphGraphPattern returns [$value]
@init{require_once('Erfurt/Sparql/Query2/GraphGraphPattern.php');}
    : GRAPH varOrIRIref groupGraphPattern {\$value = new Erfurt_Sparql_Query2_GraphGraphPattern($varOrIRIref.value); \$value->addElement($groupGraphPattern.value);}
    ;

/* sparql 1.0 r25 */
groupOrUnionGraphPattern returns [$value]
@init{
require_once('Erfurt/Sparql/Query2/GroupOrUnionGraphPattern.php');
\$value = new Erfurt_Sparql_Query2_GroupOrUnionGraphPattern();
}
    : v1=groupGraphPattern {\$value->addElement($v1.value);} ( UNION v2=groupGraphPattern {\$value->addElement($v2.value);} )*
    ;

/* sparql 1.0 r26 */
filter returns [$value]
@init{require_once('Erfurt/Sparql/Query2/Filter.php');}
    : FILTER constraint {\$value = new Erfurt_Sparql_Query2_Filter($constraint.value);}
    ;

/* sparql 1.0  r27 */
constraint returns [$value]
@after{\$value = $v.value;}
    : v=brackettedExpression
    | v=builtInCall
    | v=functionCall
    ;
/* sparql 1.0 r28 */
functionCall returns [$value]
    : iriRef argList {\$value = new Erfurt_Sparql_Query2_Function($iriRef.value, $argList.value);}
    ;

/* sparql 1.0 r29 */
argList returns [$value]
@init{\$value=array();}
    : OPEN_BRACE WS* CLOSE_BRACE
    | OPEN_BRACE e1=expression {\$value []= $e1.value;}
        ( COMMA e2=expression {\$value []= $e2.value;})* CLOSE_BRACE
    ;

/* sparql 1.0 r30 */
constructTemplate returns [$value]
@init{\$value = new Erfurt_Sparql_Query2_ConstructTemplate();}
    : OPEN_CURLY_BRACE (constructTriples {\$value->setElements($constructTriples.value);})? CLOSE_CURLY_BRACE
    ;

/* sparql 1.0 r31 */
constructTriples returns [$value]
@init{\$value=array();}
    : triplesSameSubject {\$value []= $triplesSameSubject.value;} ( DOT (c=constructTriples {\$value = array_merge(\$value, $c.value);})? )?
    ;

/* sparql 1.0 r32 */
triplesSameSubject returns [$value]
@init{require_once('Erfurt/Sparql/Query2/TriplesSameSubject.php');}
    : varOrTerm propertyListNotEmpty {\$value = new Erfurt_Sparql_Query2_TriplesSameSubject($varOrTerm.value, $propertyListNotEmpty.value);}
    | triplesNode propertyList {\$value = new Erfurt_Sparql_Query2_TriplesSameSubject($triplesNode.value, $propertyList.value);}
    ;

/* sparql 1.0 r33 */
propertyListNotEmpty returns [$value]
@init{\$value = array();\$prop=array();}
    : v1=verb ol1=objectList {\$prop['pred']=$v1.value; \$prop['obj']=$ol1.value; \$value []= \$prop;}
        ( SEMICOLON ( v2=verb ol2=objectList {\$prop['pred']=$v2.value; \$prop['obj']=$ol2.value; \$value []= \$prop;})? )*
    ;

/* sparql 1.0 r34 */
propertyList returns [$value]
@init{\$value = array();}
    : (propertyListNotEmpty {\$value = $propertyListNotEmpty.value;})?
    ;

/* sparql 1.0 r35 */
objectList returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/ObjectList.php';}
    : o1=object {\$value = new Erfurt_Sparql_Query2_ObjectList(array($o1.value));}
        ( COMMA o2=object {\$value -> addElement($o2.value);} )*
    ;

/* sparql 1.0 r36 */
object returns [$value]
    : graphNode {\$value = $graphNode.value;}
    ;

/* sparql 1.0  r37 */
verb returns [$value]
@init{require_once('Erfurt/Sparql/Query2/A.php');}
    : varOrIRIref {\$value = $varOrIRIref.value;}
    | A {\$value = new Erfurt_Sparql_Query2_A();}
    ;

/* sparql 1.0 r38 */
triplesNode returns [$value]
    : collection {\$value = $collection.value;}
    | blankNodePropertyList {\$value = $blankNodePropertyList.value;}
    ;

/* sparql 1.0 r39 */
blankNodePropertyList returns [$value]
    : OPEN_SQUARE_BRACE propertyListNotEmpty CLOSE_SQUARE_BRACE {\$value = $propertyListNotEmpty.value;}
    ;

/* sparql 1.0 r40 */
collection returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/Collection.php';
\$list=array();}
@after{\$value = new Erfurt_Sparql_Query2_Collection(\$list);}
    : OPEN_BRACE (graphNode { \$list []= $graphNode.value;})+ CLOSE_BRACE
    ;

/* sparql 1.0 r41 */
graphNode returns [$value]
    : varOrTerm {\$value=$varOrTerm.value;}
    | triplesNode {\$value=$triplesNode.value;}
    ;

/* sparql 1.0 r42 */
varOrTerm returns [$value]
    : variable {\$value = $variable.value;}
    | graphTerm {\$value = $graphTerm.value;}
    ;

/* sparql 1.0 r43 */
varOrIRIref returns [$value]
    : variable {\$value = $variable.value;}
    | iriRef {\$value = $iriRef.value;}
    ;

/* sparql 1.0 r44 */
variable returns [$value]
@init{require_once('Erfurt/Sparql/Query2/Var.php');}
@after{\$value = new Erfurt_Sparql_Query2_Var($v.text); \$value->setVarLabelType(\$vartype);}
    : v=VAR1 {\$vartype = "?";}
    | v=VAR2 {\$vartype = "$";}
    ;

/* sparql 1.0 r45 */
graphTerm returns [$value]
@init{require_once('Erfurt/Sparql/Query2/Nil.php');}
    : v=iriRef {\$value=$v.value;}
    | v=rdfLiteral {\$value=$v.value;}
    | v=numericLiteral {\$value=$v.value;}
    | v=booleanLiteral {\$value=$v.value;}
    | v=blankNode {\$value=$v.value;}
    | OPEN_BRACE WS* CLOSE_BRACE {\$value=new Erfurt_Sparql_Query2_Nil();}
    ;

/* sparql 1.0 r46 */
expression returns [$value]
    : conditionalOrExpression {\$value = $conditionalOrExpression.value;}
    ;

/* sparql 1.0 r47 */
conditionalOrExpression returns [$value]
@init{\$v = array();}
@after{\$value =  new Erfurt_Sparql_Query2_ConditionalOrExpression(\$v);}
    : c1=conditionalAndExpression {\$v[]=$c1.value;}
    ( OR c2=conditionalAndExpression {\$v[]=$c2.value;})*
    ;

/* sparql 1.0 r48*/
conditionalAndExpression returns [$value]
@init{\$v = array();}
@after{\$value = new Erfurt_Sparql_Query2_ConditionalAndExpression(\$v);}
    : v1=valueLogical {\$v[] = $v1.value;} ( AND v2=valueLogical {\$v[]=$v2.value;} )*
    ;

/* sparql 1.0 r49 */
valueLogical returns [$value]
    : relationalExpression {\$value = $relationalExpression.value;}
    ;

/* sparql 1.0 r50 */
relationalExpression returns [$value]
    : n1=numericExpression {\$value = $n1.value;}
        ( EQUAL n2=numericExpression {\$value = new Erfurt_Sparql_Query2_Equals($n1.value, $n2.value);}
        | NOT_EQUAL n2=numericExpression {\$value = new Erfurt_Sparql_Query2_NotEquals($n1.value, $n2.value);}
        | LESS n2=numericExpression {\$value = new Erfurt_Sparql_Query2_Smaller($n1.value, $n2.value);}
        | GREATER n2=numericExpression {\$value = new Erfurt_Sparql_Query2_Larger($n1.value, $n2.value);}
        | LESS_EQUAL n2=numericExpression {\$value = new Erfurt_Sparql_Query2_SmallerEqual($n1.value, $n2.value);}
        | GREATER_EQUAL n2=numericExpression{\$value = new Erfurt_Sparql_Query2_LargerEqual($n1.value, $n2.value);}
        )?
    ;

/* sparql 1.0 r51 */
numericExpression returns [$value]
    : additiveExpression {\$value = $additiveExpression.value;}
    ;

/* sparql 1.0 r52 */
additiveExpression returns [$value]
@init{\$value = new Erfurt_Sparql_Query2_AdditiveExpression(); \$op=null; \$v2=null;}
    : m1=multiplicativeExpression {\$value->addElement('+', $m1.value);}
        (( op=PLUS m2=multiplicativeExpression {\$op=$op.text; \$v2=$m2.value;}
        | op=MINUS m2=multiplicativeExpression {\$op=$op.text; \$v2=$m2.value;}
        | n=numericLiteralPositive {\$op='+'; \$v2=$n.value;}
        | n=numericLiteralNegative {\$op='-'; \$v2=$n.value;}
            ){\$value->addElement(\$op, \$v2);})*
    ;

/* sparql 1.0 r53 */
multiplicativeExpression returns [$value]
@init{\$value=new Erfurt_Sparql_Query2_MultiplicativeExpression();}
    : u1=unaryExpression {\$value->addElement('*', $u1.value);}
        (( op=ASTERISK u2=unaryExpression | op=DIVIDE u2=unaryExpression ){\$value->addElement($op.text, $u2.value);})*
    ;

/* sparql 1.0 r54 */
unaryExpression returns [$value]
    : NOT_SIGN e=primaryExpression {\$value = new Erfurt_Sparql_Query2_UnaryExpressionNot($e.value);}
    | PLUS e=primaryExpression {\$value = new Erfurt_Sparql_Query2_UnaryExpressionPlus($e.value);}
    | MINUS e=primaryExpression {\$value = new Erfurt_Sparql_Query2_UnaryExpressionMinus($e.value);}
    | e=primaryExpression {\$value = $e.value;}
    ;

/* sparql 1.0 r55 */
primaryExpression returns [$value]
@after{\$value = \$v;}
    : v=brackettedExpression {\$v = $v.value;}
    | v=builtInCall {\$v = $v.value;}
    | v=iriRefOrFunction {\$v = $v.value;}
    | v=rdfLiteral {\$v = $v.value;}
    | v=numericLiteral {\$v = $v.value;}
    | v=booleanLiteral {\$v = $v.value;}
    | v=variable {\$v = $v.value;}
    ;

/* sparql 1.0 r56 */
brackettedExpression returns [$value]
    : OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_BrackettedExpression($e.value);}
    ;

/* sparql 1.0 r57 */
builtInCall returns [$value]
    : STR OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_Str($e.value);}
    | LANG OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_Lang($e.value);}
    | LANGMATCHES OPEN_BRACE e1=expression COMMA e2=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_LangMatches($e1.value, $e2.value);}
    | DATATYPE OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_Datatype($e.value);}
    | BOUND OPEN_BRACE variable CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_bound($variable.value);}
    | SAMETERM OPEN_BRACE e1=expression COMMA e2=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_sameTerm($e1.value, $e2.value);}
    | ISIRI OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_isIri($e.value);}
    | ISURI OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_isUri($e.value);}
    | ISBLANK OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_isBlank($e.value);}
    | ISLITERAL OPEN_BRACE e=expression CLOSE_BRACE {\$value = new Erfurt_Sparql_Query2_isLiteral($e.value);}
    | regexExpression {\$value = $regexExpression.value;}
    ;

/* sparql 1.0 r58 */
regexExpression returns [$value]
    : REGEX OPEN_BRACE e1=expression COMMA e2=expression ( COMMA e3=expression )? CLOSE_BRACE
    {\$value = new Erfurt_Sparql_Query2_Regex($e1.value, $e2.value, $e3.value);}
    ;

/* sparql 1.0 r59 */
iriRefOrFunction returns [$value]
@init{\$al = null;\$i=null;}
@after{
if(isset(\$al)){
    \$value = new Erfurt_Sparql_Query2_Function(\$i, \$al);
} else{\$value = \$i;}
}
    : iriRef {\$i=$iriRef.value;}
        (argList {\$al = $argList.value;})?
    ;

/* sparql 1.0 r60 */
rdfLiteral returns [$value]
@init{require_once('Erfurt/Sparql/Query2/RDFLiteral.php');}
    : string {\$value = new Erfurt_Sparql_Query2_RDFLiteral($string.text);}
        ( LANGTAG {\$value->setLanguageTag($LANGTAG.text);} 
        | ( REFERENCE iriRef {\$value->setDatatype($iriRef.value);} ) )?
    ;

/* sparql 1.0 r61 */
numericLiteral returns [$value]
    : (n=numericLiteralUnsigned
	| n=numericLiteralPositive
	| n=numericLiteralNegative ) {\$value=$n.value;}
    ;

/* sparql 1.0 r62 */
numericLiteralUnsigned returns [$value]
@init{require_once('Erfurt/Sparql/Query2/NumericLiteral.php');}
    : v=INTEGER {\$value = new Erfurt_Sparql_Query2_NumericLiteral((int)$v.text);}
    | v=DECIMAL {\$value = new Erfurt_Sparql_Query2_NumericLiteral((float)$v.text);}
    | v=DOUBLE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((double)$v.text);}
    ;

/* sparql 1.0 r63 */
numericLiteralPositive returns [$value]
@init{require_once('Erfurt/Sparql/Query2/NumericLiteral.php');}
    : v=INTEGER_POSITIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((int)$v.text);}
    | v=DECIMAL_POSITIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((float)$v.text);}
    | v=DOUBLE_POSITIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((double)$v.text);}
    ;

/* sparql 1.0 r64 */
numericLiteralNegative returns [$value]
@init{require_once('Erfurt/Sparql/Query2/NumericLiteral.php');}
    : v=INTEGER_NEGATIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((int)$v.text);}
    | v=DECIMAL_NEGATIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((float)$v.text);}
    | v=DOUBLE_NEGATIVE {\$value = new Erfurt_Sparql_Query2_NumericLiteral((double)$v.text);}
    ;

/* sparql 1.0 r65 */
booleanLiteral returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/BooleanLiteral.php'; \$v=null;}
@after{\$value = new Erfurt_Sparql_Query2_BooleanLiteral((bool)\$v);}
    : TRUE {\$v=1;}
    | FALSE {\$v=0;}
    ;

/* sparql 1.0 r66 */
string
    : STRING_LITERAL1
    | STRING_LITERAL2
    | STRING_LITERAL_LONG1
    | STRING_LITERAL_LONG2
    ;

/* sparql 1.0 r67 */
iriRef returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/IriRef.php';}
    : IRI_REF {\$value = new Erfurt_Sparql_Query2_IriRef($IRI_REF.text);}
    | prefixedName {\$value = new Erfurt_Sparql_Query2_IriRef($prefixedName.text);}
    ;

/* sparql 1.0 r68 */
prefixedName
    : PNAME_LN
    | PNAME_NS
    ;

/* sparql 1.0 r69 */
blankNode returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/BlankNode.php'; \$v=null;}
@after{\$value = new Erfurt_Sparql_Query2_BlankNode(\$v);}
    : v=BLANK_NODE_LABEL {\$v = $v.text;}
    | OPEN_SQUARE_BRACE (WS)* CLOSE_SQUARE_BRACE {\$v='';}
    ;

BASE
    : ('B'|'b')('A'|'a')('S'|'s')('E'|'e')
    ;

PREFIX
    : ('P'|'p')('R'|'r')('E'|'e')('F'|'f')('I'|'i')('X'|'x')
    ;

MODIFY
	: ('M'|'m')('O'|'o')('D'|'d')('I'|'i')('F'|'f')('Y'|'y')
	;

DELETE
	: ('D'|'d')('E'|'e')('L'|'l')('E'|'e')('T'|'t')('E'|'e')
	;

INSERT
	: ('I'|'i')('N'|'n')('S'|'s')('E'|'e')('R'|'r')('T'|'t')
	;

DATA
	: ('D'|'d')('A'|'a')('T'|'t')('A'|'a')
	;

INTO
	:('I'|'i')('N'|'n')('T'|'t')('O'|'o')
	;

LOAD
	: ('L'|'l')('O'|'o')('A'|'a')('D'|'d')
	;

CLEAR
	: ('C'|'c')('L'|'l')('E'|'e')('A'|'a')('R'|'r')
	;
CREATE
	: ('C'|'c')('R'|'r')('E'|'e')('A'|'a')('T'|'t')('E'|'e')
	;

SILENT
	: ('S'|'s')('I'|'i')('L'|'l')('E'|'e')('N'|'n')('T'|'t')
	;

DROP
	: ('D'|'d')('R'|'r')('O'|'o')('P'|'p')
	;

EXISTS
	: ('E'|'e')('X'|'x')('I'|'i')('S'|'s')('T'|'t')('S'|'s')
	;
	
UNSAID
	: ('U'|'u')('N'|'n')('S'|'s')('A'|'a')('I'|'i')('D'|'d')
	;

NOT
	: ('N'|'n')('O'|'o')('T'|'t')
	;

SELECT
    : ('S'|'s')('E'|'e')('L'|'l')('E'|'e')('C'|'c')('T'|'t')
    ;

DISTINCT
    : ('D'|'d')('I'|'i')('S'|'s')('T'|'t')('I'|'i')('N'|'n')('C'|'c')('T'|'t')
    ;

REDUCED
    : ('R'|'r')('E'|'e')('D'|'d')('U'|'u')('C'|'c')('E'|'e')('D'|'d')
    ;

CONSTRUCT
    : ('C'|'c')('O'|'o')('N'|'n')('S'|'s')('T'|'t')('R'|'r')('U'|'u')('C'|'c')('T'|'t')
    ;

DESCRIBE
    : ('D'|'d')('E'|'e')('S'|'s')('C'|'c')('R'|'r')('I'|'i')('B'|'b')('E'|'e')
    ;

ASK
    : ('A'|'a')('S'|'s')('K'|'k')
    ;

FROM
    : ('F'|'f')('R'|'r')('O'|'o')('M'|'m')
    ;

NAMED
    : ('N'|'n')('A'|'a')('M'|'m')('E'|'e')('D'|'d')
    ;   

WHERE
    : ('W'|'w')('H'|'h')('E'|'e')('R'|'r')('E'|'e')
    ;

ORDER
    : ('O'|'o')('R'|'r')('D'|'d')('E'|'e')('R'|'r')
    ;

GROUP
	: ('G'|'g')('R'|'r')('O'|'o')('U'|'u')('P'|'p')
	;

HAVING
	: ('H'|'h')('A'|'a')('V'|'v')('I'|'i')('N'|'n')('G'|'g')
	;

BY
    : ('B'|'b')('Y'|'y')
    ;

ASC
    : ('A'|'a')('S'|'s')('C'|'c')
    ;

DESC
    : ('D'|'d')('E'|'e')('S'|'s')('C'|'c')
    ;

LIMIT
    : ('L'|'l')('I'|'i')('M'|'m')('I'|'i')('T'|'t')
    ;

OFFSET
    : ('O'|'o')('F'|'f')('F'|'f')('S'|'s')('E'|'e')('T'|'t')
    ;

OPTIONAL
    : ('O'|'o')('P'|'p')('T'|'t')('I'|'i')('O'|'o')('N'|'n')('A'|'a')('L'|'l')
    ;  

GRAPH
    : ('G'|'g')('R'|'r')('A'|'a')('P'|'p')('H'|'h')
    ;   

UNION
    : ('U'|'u')('N'|'n')('I'|'i')('O'|'o')('N'|'n')
    ;

FILTER
    : ('F'|'f')('I'|'i')('L'|'l')('T'|'t')('E'|'e')('R'|'r')
    ;

A
    : ('a')
    ;

AS
	: ('A'|'a')('S'|'s')
	;

STR
    : ('S'|'s')('T'|'t')('R'|'r')
    ;

LANG
    : ('L'|'l')('A'|'a')('N'|'n')('G'|'g')
    ;

LANGMATCHES
    : ('L'|'l')('A'|'a')('N'|'n')('G'|'g')('M'|'m')('A'|'a')('T'|'t')('C'|'c')('H'|'h')('E'|'e')('S'|'s')
    ;

DATATYPE
    : ('D'|'d')('A'|'a')('T'|'t')('A'|'a')('T'|'t')('Y'|'y')('P'|'p')('E'|'e')
    ;

BOUND
    : ('B'|'b')('O'|'o')('U'|'u')('N'|'n')('D'|'d')
    ;

SAMETERM
    : ('S'|'s')('A'|'a')('M'|'m')('E'|'e')('T'|'t')('E'|'e')('R'|'r')('M'|'m')
    ;

ISIRI
    : ('I'|'i')('S'|'s')('I'|'i')('R'|'r')('I'|'i')
    ;

ISURI
    : ('I'|'i')('S'|'s')('U'|'u')('R'|'r')('I'|'i')
    ;

ISBLANK
    : ('I'|'i')('S'|'s')('B'|'b')('L'|'l')('A'|'a')('N'|'n')('K'|'k')
    ;

ISLITERAL
    : ('I'|'i')('S'|'s')('L'|'l')('I'|'i')('T'|'t')('E'|'e')('R'|'r')('A'|'a')('L'|'l')
    ;

REGEX
    : ('R'|'r')('E'|'e')('G'|'g')('E'|'e')('X'|'x')
    ;

COUNT
	: ('C'|'c')('O'|'o')('U'|'u')('N'|'n')('T'|'t')
	;

SUM
	:('S'|'s')('U'|'u')('M'|'m')
	;

MIN
	:('M'|'m')('I'|'i')('N'|'n')
	;

MAX
	: ('M'|'m')('A'|'a')('X'|'x')
	;

AVG
	: ('A'|'a')('V'|'v')('G'|'g')
	;

TRUE
    : ('T'|'t')('R'|'r')('U'|'u')('E'|'e')
    ;

FALSE
    : ('F'|'f')('A'|'a')('L'|'l')('S'|'s')('E'|'e')
    ;

IF
	: ('I'|'i')('F'|'f')
	;

COALESCE
	: ('C'|'c')('O'|'o')('A'|'a')('L'|'l')('E'|'e')('S'|'s')('C'|'c')('E'|'e')
	;

IRI_REF
    : LESS ( options {greedy=false;} : ~(LESS | GREATER | '"' | OPEN_CURLY_BRACE | CLOSE_CURLY_BRACE | '|' | '^' | '\\' | '`' | ('\u0000'..'\u0020')) )* GREATER
    {\$this->setText(substr(\$this->getText(), 1, strlen(\$this->getText()) - 2)); }
    ;

PNAME_NS
    : p=PN_PREFIX? ':'
    ;

PNAME_LN
    : PNAME_NS PN_LOCAL
    ;

VAR1
    : '?' v=VARNAME {\$this->setText($v.text);}
    ;

VAR2
    : '$' v=VARNAME {\$this->setText($v.text);}
    ;

LANGTAG
    : '@' (('a'..'z')('A'..'Z'))+ (MINUS (('a'..'z')('A'..'Z')('0'..'9'))+)*
    {\$this->setText(substr(\$this->getText(), 1, strlen(\$this->getText()) - 1)); }
    ;

INTEGER
    : ('0'..'9')+
    ;

DECIMAL
    : ('0'..'9')+ DOT ('0'..'9')*
    | DOT ('0'..'9')+
    ;

DOUBLE
    : DIGIT+ DOT DIGIT* EXPONENT
    | DOT DIGIT+ EXPONENT
    | DIGIT+ EXPONENT
    ;

fragment
DIGIT
    : '0'..'9'
    ;

INTEGER_POSITIVE
    : PLUS n=INTEGER {\$this->setText($n.text);}
    ;

DECIMAL_POSITIVE
    : PLUS n=DECIMAL {\$this->setText($n.text);}
    ;

DOUBLE_POSITIVE
    : PLUS n=DOUBLE {\$this->setText($n.text);}
    ;

INTEGER_NEGATIVE
    : MINUS n=INTEGER {\$this->setText($n.text);}
    ;

DECIMAL_NEGATIVE
    : MINUS n=DECIMAL {\$this->setText($n.text);}
    ;

DOUBLE_NEGATIVE
    : MINUS n=DOUBLE {\$this->setText($n.text);}
    ;

fragment
EXPONENT : ('e'|'E') (PLUS|MINUS)? ('0'..'9')+ ;

STRING_LITERAL1
    : '\'' ( options {greedy=false;} : ~('\u0027' | '\u005C' | '\u000A' | '\u000D') | ECHAR )* '\''
    ;

STRING_LITERAL2
    : '"'  ( options {greedy=false;} : ~('\u0022' | '\u005C' | '\u000A' | '\u000D') | ECHAR )* '"'
    ;

STRING_LITERAL_LONG1
    :   '\'\'\'' ( options {greedy=false;} : ( '\'' | '\'\'' )? ( ~( '\'' | '\\' ) | ECHAR ) )* '\'\'\''
    ;

STRING_LITERAL_LONG2
    : '"""' ( options {greedy=false;} : ( '"' | '""' )? ( ~( '"' | '\\' ) | ECHAR ) )* '"""'
    ;

fragment
ECHAR
    : '\\' ('t' | 'b' | 'n' | 'r' | 'f' | '\\' | '"' | '\'')
    ;

//NIL
//    : OPEN_BRACE WS* CLOSE_BRACE
//    ;

//fragment
WS
    : (' '| '\t'| EOL) {$channel=HIDDEN; }
    ;

//ANON
//    : OPEN_SQUARE_BRACE (WS)* CLOSE_SQUARE_BRACE {\$this->setText(""); }
//    ;

fragment
PN_CHARS_BASE
    : 'A'..'Z'
    | 'a'..'z'
    | '\u00C0'..'\u00D6'
    | '\u00D8'..'\u00F6'
    | '\u00F8'..'\u02FF'
    | '\u0370'..'\u037D'
    | '\u037F'..'\u1FFF'
    | '\u200C'..'\u200D'
    | '\u2070'..'\u218F'
    | '\u2C00'..'\u2FEF'
    | '\u3001'..'\uD7FF'
    | '\uF900'..'\uFDCF'
    | '\uFDF0'..'\uFFFD'
    ;

fragment
PN_CHARS_U
    : PN_CHARS_BASE | '_'
    ;

fragment
VARNAME
    : ( PN_CHARS_U | ('0'..'9') ) ( PN_CHARS_U | ('0'..'9') | '\u00B7' | '\u0300'..'\u036F' | '\u203F'..'\u2040' )*
    ;

fragment
PN_CHARS
    : PN_CHARS_U
    | MINUS
    | ('0'..'9')
    | '\u00B7' 
    | '\u0300'..'\u036F'
    | '\u203F'..'\u2040'
    ;

fragment
PN_PREFIX
    : PN_CHARS_BASE ((PN_CHARS|DOT)* PN_CHARS)?
    ;


fragment
PN_LOCAL
    : ( PN_CHARS_U | ('0'..'9') ) ((PN_CHARS|DOT)* PN_CHARS)?
    ;

BLANK_NODE_LABEL
    : '_:' t=PN_LOCAL {\$this->setText($t.text); }
    ;

REFERENCE
	: '^^'
	;


AND
    : '&&'
    ;

OR
    : '||'
    ;

COMMENT 
    : '#' .* EOL { $channel=HIDDEN; }
    ;

fragment
EOL
    : '\n' | '\r'
    ;

OPEN_CURLY_BRACE
	: '{'
	;

CLOSE_CURLY_BRACE
	: '}'
	;

SEMICOLON
    : ';'
    ;

DOT
    : '.'
    ;

PLUS
    : '+'
    ;

MINUS
    : '-'
    ;

ASTERISK
    : '*'
    ;

COMMA
    : ','
    ;

NOT_SIGN
    : '!'
    ;
DIVIDE
    : '/'
    ;

EQUAL
    : '='
    ;

LESS
	: '<'
	;

GREATER
	: '>'
	;

OPEN_BRACE
    : '('
    ;

CLOSE_BRACE
    : ')'
    ;

LESS_EQUAL
    : '<='
    ;

GREATER_EQUAL
    : '>='
    ;

NOT_EQUAL
    : '!='
    ;

OPEN_SQUARE_BRACE
    : '['
    ;

CLOSE_SQUARE_BRACE
    : ']'
    ;
