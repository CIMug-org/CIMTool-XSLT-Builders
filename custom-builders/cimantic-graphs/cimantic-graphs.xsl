<?xml version="1.0" encoding="UTF-8"?>
<!--
This builder is released under a BSD-3 license as part of the CIMantic Graphs library developed by PNNL.

This software was created under a project sponsored by the U.S. Department of Energy’s Office of Electricity, 
an agency of the United States Government. Neither the United States Government nor the United States Department 
of Energy, nor Battelle, nor any of their employees, nor any jurisdiction or organization that has cooperated 
in the development of these materials, makes any warranty, express or implied, or assumes any legal liability 
or responsibility for the accuracy, completeness, or usefulness or any information, apparatus, product, software, 
or process disclosed, or represents that its use would not infringe privately owned rights.

Reference herein to any specific commercial product, process, or service by trade name, trademark, manufacturer, 
or otherwise does not necessarily constitute or imply its endorsement, recommendation, or favoring by the United 
States Government or any agency thereof, or Battelle Memorial Institute. The views and opinions of authors expressed 
herein do not necessarily state or reflect those of the United States Government or any agency thereof.

PACIFIC NORTHWEST NATIONAL LABORATORY operated by BATTELLE for the UNITED STATES DEPARTMENT OF ENERGY 
under Contract DE-AC05-76RL01830
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:a="http://langdale.com.au/2005/Message#"
    xmlns:sawsdl="http://www.w3.org/ns/sawsdl"
    xmlns="http://langdale.com.au/2009/Indent">

    <xsl:output indent="yes" method="xml" encoding="utf-8" />
    <xsl:param name="version"/>
    <xsl:param name="baseURI"/>
    <xsl:param name="ontologyURI"/>
    <xsl:param name="envelope">Profile</xsl:param>
    <xsl:param name="package">au.com.langdale.cimtool.generated</xsl:param>

    <!-- Key for tracing parent-child inheritance -->
    <xsl:key name="classes-by-super" match="a:Root|a:ComplexType" use="a:SuperType/@name"/>

    <!-- Template for top-level item in schema file -->
    <xsl:template match="a:Catalog">
        <document>
            <!-- Header text with library imports -->
            <item>from __future__ import annotations</item>
            <item>from dataclasses import dataclass, field</item>
            <item>from typing import Optional</item>
            <item>from enum import Enum</item>
            <list begin="'''" indent="    " end="'''">
                <item>Annotated CIMantic Graphs data profile for <xsl:value-of select="$envelope" /></item>
                <item>Generated by CIMTool http://cimtool.org</item>
            </list>

        <!-- Start with top-level concrete classes and then work down -->
        <xsl:for-each select="a:Root[not(a:SuperType)]">
            <xsl:call-template name="super"/>
        </xsl:for-each>
        <!-- Then do top-level abstract classes and work down -->
        <xsl:for-each select="a:ComplexType[not(a:SuperType)]">
            <xsl:call-template name="super"/>
        </xsl:for-each>
        <!-- Then do all enumerations -->
        <xsl:for-each select="a:EnumeratedType">
            <xsl:call-template name="enumeration"/>
        </xsl:for-each>
        <!-- Then do all primitives -->
        <xsl:for-each select="a:SimpleType">
            <xsl:call-template name="primitive"/>
        </xsl:for-each>
        <!-- Then do all compounds -->
        <xsl:for-each select="a:CompoundType">
            <xsl:call-template name="super"/>
        </xsl:for-each>
        </document>
    </xsl:template>

    <!-- Template for top-level classes with no inheritance -->
    <xsl:template name="super">
        <!-- Create dataclass for each CIM class -->
        <item>@dataclass</item>
        <item>class <xsl:value-of select="@name"/>():</item>

        <!-- Parse all comment text, merge multiple comments into single block -->
        <list begin="    '''" indent="    " end="    '''">
            <xsl:for-each select="a:Comment">
                <xsl:call-template name="comment"/>
            </xsl:for-each>
        </list>
        <!-- Parse all simple attributes -->
        <xsl:for-each select="a:Simple">
            <list begin="" indent="    " end="">
                <xsl:call-template name="simpleattribute"/>
            </list>
        </xsl:for-each>
        <!-- Parse all attributes with datatypes / units -->
        <xsl:for-each select="a:Domain|a:Enumerated">
            <list begin="" indent="    " end="">
                <xsl:call-template name="attribute"/>
            </list>
        </xsl:for-each>
        <!-- Parse all associations to other classes -->
        <xsl:for-each select="a:Instance|a:Reference">
            <list begin="" indent="    " end="">
                <xsl:call-template name="assocation"/>
            </list>
        </xsl:for-each>
        <!-- Parse all child classes inheriting from top-level class -->
        <xsl:for-each select="key('classes-by-super', @name)">
            <xsl:call-template name="lower"/>
        </xsl:for-each>
    </xsl:template>

    <!-- Template for lower level classes -->
    <xsl:template name="lower">
        <!-- Only process the first occurrence of each SuperType -->
        <xsl:if test="generate-id() = generate-id(key('classes-by-super', a:SuperType/@name)[1])">
            <!-- Find all Root elements with the same SuperType -->
            <xsl:for-each select="key('classes-by-super', a:SuperType/@name)">
                <!-- Create dataclass for each CIM class -->
                <item>@dataclass</item>
                <item>
                    class <xsl:value-of select="@name"/>(<xsl:value-of select="a:SuperType/@name"/>):
                </item>
                <!-- Parse all comment text, merge multiple comments into single block -->
                <list begin="    '''" indent="    " end="    '''">
                    <xsl:for-each select="a:Comment">
                        <xsl:call-template name="comment"/>
                    </xsl:for-each>
                </list>
                <!-- Parse all simple attributes -->
                <xsl:for-each select="a:Simple">
                    <list begin="" indent="    " end="">
                        <xsl:call-template name="simpleattribute"/>
                    </list>
                </xsl:for-each>
                <!-- Parse all attributes with datatypes / units -->
                <xsl:for-each select="a:Domain|a:Enumerated">
                    <list begin="" indent="    " end="">
                        <xsl:call-template name="attribute"/>
                    </list>
                </xsl:for-each>
                <!-- Parse all associations to other classes -->
                <xsl:for-each select="a:Instance|a:Reference">
                    <list begin="" indent="    " end="">
                        <xsl:call-template name="assocation"/>
                    </list>
                </xsl:for-each>
                <!-- Parse all child classes inheriting from current class -->
                <xsl:for-each select="key('classes-by-super', @name)">
                    <xsl:call-template name="lower"/>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- Template for Domain attributes with datatypes -->
    <xsl:template name = 'attribute'>
        <!-- Parse attributes with cardinality of 0..1 -->
        <!-- Typing is Optional, default is None -->
        <xsl:if test="@maxOccurs &lt;= 1">
            <xsl:variable name="xstype">
                <xsl:call-template name="type">
                    <xsl:with-param name="xstype" select="@xstype"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Write dataclass field with typing and default -->
            <item>
                <xsl:value-of select="@name"/>: Optional[
                <xsl:value-of select="$xstype"/>  |
                <xsl:value-of select="@type"/> ] = field(
            </item>
            <list begin="" indent="    " end="">
                default = None,
            </list>
            <!-- Write metadata regarding cardinality, etc. -->
            <list begin="" indent="    " end="">
                metadata = {
                <list begin="" indent="    " end="">
                    <xsl:call-template name="attr_metadata"/>
                </list>
                })
            </list>
            <!-- Parse all comment text, merge multiple comments into single block -->
            <list begin="'''" indent="" end="'''">
                <xsl:for-each select="a:Comment">
                    <xsl:call-template name="comment"/>
                </xsl:for-each>
            </list>
        </xsl:if>
    </xsl:template>

    <!-- Template for Simple attributes with primitive datatypes -->
    <xsl:template name = 'simpleattribute'>
        <!-- Parse attributes with cardinality of 0..1 -->
        <!-- Typing is Optional, default is None -->
        <xsl:if test="@maxOccurs &lt;= 1">
            <!-- Convert CIM primitives to python typing -->
            <xsl:variable name="xstype">
                <xsl:call-template name="type">
                    <xsl:with-param name="xstype" select="@xstype"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Error handling for invalid or missing names -->
            <xsl:variable name="name">
                <xsl:call-template name="name">
                    <xsl:with-param name="name" select="@name"/>
                    <xsl:with-param name="type" select="@xstype"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Write dataclass field with typing and default -->
            <item>
                <xsl:value-of select="$name"/>: Optional[
                <xsl:value-of select="$xstype"/> ] = field(
            </item>
            <list begin="" indent="    " end="">
                default = None,
            </list>
            <!-- Write metadata regarding cardinality, etc. -->
            <list begin="" indent="    " end="">
                metadata = {
                <list begin="" indent="    " end="">
                    <xsl:call-template name="attr_metadata"/>
                </list>
                })
            </list>
            <!-- Parse all comment text, merge multiple comments into single block -->
            <list begin="'''" indent="" end="'''">
                <xsl:for-each select="a:Comment">
                    <xsl:call-template name="comment"/>
                </xsl:for-each>
            </list>
        </xsl:if>
    </xsl:template>

    <!-- Template for associations with other classes -->
    <xsl:template name = 'assocation'>
        <!-- Parse assocations with cardinality of 0..1 -->
        <!-- Typing is Optional, default is None -->
        <xsl:if test="@maxOccurs &lt;= 1">
            <!-- Error handling for invalid or missing names -->
            <xsl:variable name="name">
                <xsl:call-template name="name">
                    <xsl:with-param name="name" select="@name"/>
                    <xsl:with-param name="type" select="@type"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Write dataclass field with typing and default -->
            <item>
                <xsl:value-of select="$name"/>: Optional[ str |
                <xsl:value-of select="@type"/> ] = field(
            </item>
            <list begin="" indent="    " end="">
                default = None,
            </list>
        </xsl:if>
        <!-- Parse datatype of attributes with cardinality of many -->
        <!-- Typing is List, default is [] -->
        <xsl:if test="@maxOccurs &gt; 1 or @maxOccurs = 'unbounded'">
            <!-- Error handling for invalid or missing names -->
            <xsl:variable name="name">
                <xsl:call-template name="name">
                    <xsl:with-param name="name" select="@name"/>
                    <xsl:with-param name="type" select="@type"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Write dataclass field with typing and default -->
            <item>
                <xsl:value-of select="$name"/>: list[ str |
                <xsl:value-of select="@type"/> ] = field(
            </item>
            <list begin="" indent="    " end="">
                default_factory = list,
            </list>
        </xsl:if>
        <!-- Write metadata regarding cardinality, inverse, etc. -->
        <list begin="" indent="    " end="">
            metadata = {
            <list begin="" indent="    " end="">
                <xsl:call-template name="assc_metadata"/>
            </list>
            })
        </list>
        <!-- Parse all comment text, merge multiple comments into single block -->
        <list begin="'''" indent="" end="'''">
            <xsl:for-each select="a:Comment">
                <xsl:call-template name="comment"/>
            </xsl:for-each>
        </list>
    </xsl:template>

    <!-- Template for enumerations -->
    <xsl:template name="enumeration">
        <!-- Parse enumeration name -->
        <item>class <xsl:value-of select="@name"/>( Enum ):</item>
        <!-- Parse all comment text, merge multiple comments into single block -->
        <list begin="    '''" indent="    " end="    '''">
            <xsl:for-each select="a:Comment">
                <xsl:call-template name="comment"/>
            </xsl:for-each>
        </list>
        <!-- Parse enumeration value -->
        <xsl:for-each select="a:EnumeratedValue">
            <list begin="" indent="    " end="">
                <xsl:call-template name="enumvalue"/>
            </list>
        </xsl:for-each>
    </xsl:template>

    <!-- Template for primitives -->
    <xsl:template name="primitive">
        <xsl:variable name="xstype">
            <xsl:call-template name="type">
                <xsl:with-param name="xstype" select="@xstype"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- Parse primitve name and type -->
        <item>@dataclass</item>
        <item>class <xsl:value-of select="@name"/>():</item>
            <list begin="" indent="    " end="">
                value: <xsl:value-of select="$xstype"/> = field(default=None)
            </list>
        <!-- Parse all comment text, merge multiple comments into single block -->
        <list begin="    '''" indent="    " end="    '''">
            <xsl:for-each select="a:Comment">
                <xsl:call-template name="comment"/>
            </xsl:for-each>
        </list>

    </xsl:template>

    <!-- Template for wrapping comment text -->
    <xsl:template name="comment">
        <wrap width="70">
            <xsl:value-of select="."/>
        </wrap>
    </xsl:template>

    <!-- Template for attribute metadata -->
    <xsl:template name="attr_metadata">
        <!-- Use stereotype label if provided, otherwise, use 'Attribute' -->
        <xsl:if test="a:Stereotype/@label">
            <item> 'type': '<xsl:value-of select="a:Stereotype/@label"/>', </item>
        </xsl:if>
        <xsl:if test="not(a:Stereotype/@label)">
            <item> 'type': 'Attribute', </item>
        </xsl:if>
        <item> 'minOccurs': '<xsl:value-of select="@minOccurs"/>', </item>
        <item> 'maxOccurs': '<xsl:value-of select="@maxOccurs"/>' </item>
    </xsl:template>

    <!-- Template for association metadata -->
    <xsl:template name="assc_metadata">
        <!-- Use stereotype label if provided, otherwise, use 'Association' -->
        <xsl:if test="a:Stereotype/@label">
            <item> 'type': '<xsl:value-of select="a:Stereotype/@label"/>', </item>
        </xsl:if>
        <xsl:if test="not(a:Stereotype/@label)">
            <item> 'type': 'Association', </item>
        </xsl:if>
        <item> 'minOccurs': '<xsl:value-of select="@minOccurs"/>', </item>
        <item> 'maxOccurs': '<xsl:value-of select="@maxOccurs"/>', </item>
        <item> 'inverse': '<xsl:value-of select="substring-after(@inverseBaseProperty,'#')"/>' </item>
    </xsl:template>

    <!-- Template for enumeration values -->
    <xsl:template name="enumvalue">
        <!-- Error handling for invalid or missing names -->
        <xsl:variable name="name">
            <xsl:call-template name="name">
                <xsl:with-param name="name" select="@name"/>
                <xsl:with-param name="type" select="@name"/>
            </xsl:call-template>
        </xsl:variable>
        <item>
            <xsl:value-of select="$name"/> = '<xsl:value-of select="$name"/>'
        </item>
        <!-- Parse all comment text, merge multiple comments into single block -->
        <list begin="'''" indent="" end="'''">
            <xsl:for-each select="a:Comment">
                <xsl:call-template name="comment"/>
            </xsl:for-each>
        </list>
    </xsl:template>

    <!-- Template for converting primitives to python spelling -->
    <xsl:template name="type">
        <xsl:param name="xstype" select="@xstype"/>
        <xsl:choose>
            <xsl:when test="$xstype = 'string' or @xstype = 'String'">str</xsl:when>
            <xsl:when test="$xstype = 'integer' or @xstype = 'Integer' or @xstype = 'int'">int</xsl:when>
            <xsl:when test="$xstype = 'float' or @xstype = 'Float'">float</xsl:when>
            <xsl:when test="$xstype = 'double' or @xstype = 'Double'">float</xsl:when>
            <xsl:when test="$xstype = 'boolean' or @xstype = 'Boolean'">bool</xsl:when>
            <xsl:otherwise>str</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Template for error handling of missing or reserved names -->
    <xsl:template name="name">
        <xsl:param name="name" select="@name"/>
        <xsl:param name="type" select="@type"/>
        <xsl:choose>
            <xsl:when test="contains($name,'EAID_')"><xsl:value-of select="$type"/></xsl:when>
            <xsl:when test="$name = 'and'">_and</xsl:when>
            <xsl:when test="$name = 'as'">_as</xsl:when>
            <xsl:when test="$name = 'assert'">_assert</xsl:when>
            <xsl:when test="$name = 'break'">_break</xsl:when>
            <xsl:when test="$name = 'class'">_class</xsl:when>
            <xsl:when test="$name = 'continue'">_continue</xsl:when>
            <xsl:when test="$name = 'def'">_def</xsl:when>
            <xsl:when test="$name = 'del'">_del</xsl:when>
            <xsl:when test="$name = 'elif'">_elif</xsl:when>
            <xsl:when test="$name = 'else'">_else</xsl:when>
            <xsl:when test="$name = 'except'">_except</xsl:when>
            <xsl:when test="$name = 'finally'">_finally</xsl:when>
            <xsl:when test="$name = 'for'">_for</xsl:when>
            <xsl:when test="$name = 'from'">_from</xsl:when>
            <xsl:when test="$name = 'global'">_global</xsl:when>
            <xsl:when test="$name = 'if'">_if</xsl:when>
            <xsl:when test="$name = 'import'">_import</xsl:when>
            <xsl:when test="$name = 'in'">_in</xsl:when>
            <xsl:when test="$name = 'is'">_is</xsl:when>
            <xsl:when test="$name = 'lambda'">_lambda</xsl:when>
            <xsl:when test="$name = 'nonlocal'">_nonlocal</xsl:when>
            <xsl:when test="$name = 'not'">_not</xsl:when>
            <xsl:when test="$name = 'or'">_or</xsl:when>
            <xsl:when test="$name = 'pass'">_pass</xsl:when>
            <xsl:when test="$name = 'raise'">_raise</xsl:when>
            <xsl:when test="$name = 'return'">_return</xsl:when>
            <xsl:when test="$name = 'try'">_try</xsl:when>
            <xsl:when test="$name = 'while'">_while</xsl:when>
            <xsl:when test="$name = 'with'">_with</xsl:when>
            <xsl:when test="$name = 'yield'">_yield</xsl:when>
            <xsl:otherwise><xsl:value-of select="$name"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
