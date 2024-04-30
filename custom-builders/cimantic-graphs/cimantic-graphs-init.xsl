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
    
    <!-- Template for __init__.py file -->
    <xsl:template match="a:Catalog">
        <document>
            <!-- Header text with library imports -->
            <list begin="'''" indent="    " end="'''">
                <item>Annotated CIMantic Graphs data profile init file for 
                <xsl:value-of select="$envelope" />
            </item>
                <item>Generated by CIMTool http://cimtool.org</item>
            </list>
            <!-- Import objects using profile name -->
            <item> from cimgraph.data_profile.<xsl:value-of select="$envelope" />.<xsl:value-of select="$envelope" /> import ( </item> 
            <!-- List all CIM classes to be imported, in alphabetical order -->
            <xsl:for-each select="a:Root|a:ComplexType|a:EnumeratedType|a:CompoundType|a:SimpleType">
                <xsl:sort select="name" data-type="text" order="ascending"/>
                <list begin="" indent="    " end="">
                    <xsl:value-of select="@name" />
                    <xsl:if test="position()!=last()">, </xsl:if>
                </list>
            </xsl:for-each>
            <item>)</item>
            
            <!-- List all CIM classes to be imported, in alphabetical order -->
            <item> __all__ = [ </item>
            <xsl:for-each select="a:Root|a:ComplexType|a:EnumeratedType|a:CompoundType|a:SimpleType">
                <xsl:sort select="name" data-type="text" order="ascending"/>
                <list begin="" indent="    " end="">
                    <xsl:value-of select="@name" />
                    <xsl:if test="position()!=last()">, </xsl:if>
                </list>
            </xsl:for-each>
            <item>]</item>
        </document>
    </xsl:template>
</xsl:stylesheet>