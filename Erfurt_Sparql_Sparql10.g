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

import Tokens ;

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

// TODO looks like a bug, without this fakestart i cant generate the lexer+parser...
fakestart
	: 'fake' start;


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
@init{
require_once 'Erfurt/Sparql/Query2/ConstructTemplate.php';
\$value = new Erfurt_Sparql_Query2_ConstructTemplate();}
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
@init{require_once 'Erfurt/Sparql/Query2/PropertyList.php';
\$value = new Erfurt_Sparql_Query2_PropertyList();}
    : v1=verb ol1=objectList {\$value->addProperty($v1.value, $ol1.value);}
        ( SEMICOLON ( v2=verb ol2=objectList {\$value->addProperty($v2.value, $ol2.value);})? )*
    ;

/* sparql 1.0 r34 */
propertyList returns [$value]
@init{require_once 'Erfurt/Sparql/Query2/PropertyList.php';
\$v=null;}
@after{\$value=\$v?\$v:new Erfurt_Sparql_Query2_PropertyList();}
    : (propertyListNotEmpty {\$v = $propertyListNotEmpty.value;})?
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
@init{require_once 'Erfurt/Sparql/Query2/BlankNodePropertyList.php';}
    : OPEN_SQUARE_BRACE propertyListNotEmpty CLOSE_SQUARE_BRACE {\$value = new Erfurt_Sparql_Query2_BlankNodePropertyList($propertyListNotEmpty.value);}
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
