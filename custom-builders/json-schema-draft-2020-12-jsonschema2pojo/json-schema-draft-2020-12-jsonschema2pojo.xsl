<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright 2022 UCAIug

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

  See the License for the specific language governing permissions and
  limitations under the License.
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:a="http://langdale.com.au/2005/Message#"
    xmlns:sawsdl="http://www.w3.org/ns/sawsdl"
    xmlns="http://langdale.com.au/2009/Indent">

    <xsl:output indent="yes" method="xml" encoding="utf-8" />
    <xsl:param name="version" />
    <xsl:param name="baseURI" />
    <xsl:param name="envelope">Profile</xsl:param>
	<xsl:param name="uc">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:param>
	<xsl:param name="lc">abcdefghijklmnopqrstuvwxyz</xsl:param>
	<xsl:param name="domain">
		<xsl:call-template name="reverse_tokenize">
        	<xsl:with-param name="text" select="substring-before(substring-after(translate($baseURI, $uc, $lc),'://'),'/')"/>
    	</xsl:call-template>
	</xsl:param>
	<xsl:param name="package_prefix" select="concat($domain, '.', translate($envelope, $uc, $lc))"/>
    <xsl:param name="schema_draft_version">https://json-schema.org/draft/2020-12/schema</xsl:param>
	<xsl:param name="generate_jsonschema2pojo_annotations">true</xsl:param>

	<xsl:template name="reverse_tokenize">
	    <xsl:param name="text"/>
	    <xsl:if test="contains($text, '.')">
	        <!-- recursive call -->
	        <xsl:call-template name="reverse_tokenize">
	            <xsl:with-param name="text" select="substring-after($text, '.')"/>
	        </xsl:call-template>
	        <xsl:text>.</xsl:text>
	    </xsl:if>
	    <xsl:value-of select="substring-before(concat($text, '.'), '.')"/>
	</xsl:template>

	<xsl:template name="java_type_standard">
		<xsl:variable name="class_name">
			<xsl:choose>
				<xsl:when test="self::a:Root">
					<xsl:call-template name="capitalize">
			            <xsl:with-param name="text" select="substring-after(@baseClass, '#')"/>
			        </xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="capitalize">
			            <xsl:with-param name="text" select="@name"/>
			        </xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
    	<xsl:choose>
    		<xsl:when test="@package">
    			<xsl:value-of select="concat($package_prefix, '.', translate(@package, $uc, $lc), '.', $class_name)"/>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:value-of select="concat($package_prefix, '.', $class_name)"/>
    		</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template name="java_superclass">
		<xsl:param name="super_name"/>
		<xsl:variable name="package" select="/*/node()[@name = $super_name]/@package"/>
		<xsl:variable name="class_name">
			<xsl:call-template name="capitalize">
	            <xsl:with-param name="text" select="$super_name"/>
			</xsl:call-template>
		</xsl:variable>
    	<xsl:choose>
    		<xsl:when test="$package">
    			<xsl:value-of select="concat($package_prefix, '.', translate($package, $uc, $lc), '.', $class_name)"/>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:value-of select="concat($package_prefix, '.', $class_name)"/>
    		</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template name="java_type_ref">
		<xsl:param name="type" />
		<!-- We navigate up to the top level type definition to retrieve the package name -->
		<!-- this is typically only relevant for properties within a Choice... -->
    	<xsl:variable name="ref_name" select="$type"/>
		<xsl:variable name="package" select="/*/node()[@name = $ref_name]/@package"/>
		<xsl:variable name="class_name">
			<xsl:call-template name="capitalize">
	            <xsl:with-param name="text" select="@name"/>
	        </xsl:call-template>
		</xsl:variable>
    	<xsl:choose>
    		<xsl:when test="$package">
    			<xsl:value-of select="concat($package_prefix, '.', translate($package, $uc, $lc), '.ref.', $class_name, 'Ref')"/>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:value-of select="concat($package_prefix, '.ref.', $class_name, 'Ref')"/>
    		</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template name="java_type_anonymous">
		<xsl:param name="package">
			<xsl:call-template name="retrieve_package">
        		<xsl:with-param name="node" select="current()"/>
    		</xsl:call-template>
		</xsl:param>
		<xsl:variable name="class_name">
			<xsl:call-template name="capitalize">
	            <xsl:with-param name="text" select="@name"/>
	        </xsl:call-template>
		</xsl:variable>
    	<xsl:choose>
    		<xsl:when test="$package">
    			<xsl:value-of select="concat($package_prefix, '.', translate($package, $uc, $lc), '.', $class_name)"/>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:value-of select="concat($package_prefix, '.', $class_name)"/>
    		</xsl:otherwise>
    	</xsl:choose>
	</xsl:template>

	<xsl:template name="capitalize">
		<xsl:param name="text"/>
		<xsl:value-of select="concat(translate(substring($text,1,1),$lc,$uc),substring($text,2))"/>
	</xsl:template>

	<xsl:template name="retrieve_package">
		<xsl:param name="node"/>
		<xsl:choose>
	   		<xsl:when test="$node">
	   			<xsl:choose>
		    		<xsl:when test="$node/@package">
		    			<xsl:value-of select="$node/@package"/>
		    		</xsl:when>
		    		<xsl:otherwise>
		    			<!-- recursive call -->
		    			<xsl:call-template name="retrieve_package">
		           			<xsl:with-param name="node" select="$node/.."/>
						</xsl:call-template>
		    		</xsl:otherwise>
		    	</xsl:choose>
	    	</xsl:when>
	    	<xsl:otherwise>
	    		<!-- No more parent nodes to traverse so we return the 'default' package name (i.e. the envelope package) -->
		    	<xsl:value-of select="''"></xsl:value-of>
	    	</xsl:otherwise>
	    </xsl:choose>
	</xsl:template>

	<!-- For 'javaType' generation; the appropriate Java date/time classes are correlated to match -->
	<xsl:template name="java_type">
		<xsl:param name="xstype" />
		<xsl:choose>
			<xsl:when test="$xstype = 'dateTime'">
				<xsl:value-of select="$datetime_javatype" />
			</xsl:when>
			<xsl:when test="$xstype = 'date'">
				<xsl:value-of select="$date_javatype" />
			</xsl:when>
			<xsl:when test="$xstype = 'time'">
				<xsl:value-of select="$time_javatype" />
			</xsl:when>
			<xsl:when test="$xstype = 'duration'">
				<xsl:value-of select="$duration_javatype" />
			</xsl:when>
			<!-- i.e. the <<Primitive>> MonthDay CIM class in the 61970 Domain package -->
			<xsl:when test="$xstype = 'gMonthDay'">
				<xsl:value-of select="$monthday_javatype" />
			</xsl:when>
			<xsl:otherwise>
				<!--  <item>"javaType": "<xsl:value-of select="$package" />.<xsl:value-of select="$name" />",</item> -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

    <!--  regex patterns for date/time <<Primitive>> types in the CIM model -->

    <!--
    * DATE:
    *  Type used to express a local date in ISO 8601 standard extended date format.
    *  Date as: "yyyy-mm-dd"
    *  UTC timezone is specified as: "yyyy-mm-ddZ"
    *  Local timezone relative UTC as: "yyyy-mm-dd(+/-)hh:mm"
    *
    *  NOTE:  The REGEX pattern used for validation of this type utilizes the ISO 8601 extended date format.
     -->
    <xsl:param name="date_pattern">^(([0-9]{4})-(((02)-(0[1-9]|[1][0-9]|2[0-9]))|((0[4689]|(11))-(0[1-9]|[1][0-9]|2[0-9]|(30)))|((0[13578]|(1[02]))-(0[1-9]|[1][0-9]|2[0-9]|(3[0-1])))))(Z|[+-](2[0-3]|[01][0-9])(:([0-5][0-9]))?)$</xsl:param>
	<xsl:param name="date_javatype">java.time.LocalDate</xsl:param>

    <!--
    * DATETIME:
    * Date and time as "yyyy-mm-ddThh:mm:ss.sss", which conforms with ISO 8601.
    *
    * UTC time zone is specified as: "yyyy-mm-ddThh:mm:ss.sssZ".
    * A local timezone relative UTC is specified as: "yyyy-mm-ddThh:mm:ss.sss-hh:mm".
    *
    * Type used to express a UTC combined date and time in ISO 8601 standard extended date and time format.
    * To express the time portion in UTC for a date time; a Z is added directly after the time without a space.
    * Z is the zone designator for the zero UTC offset.
    *
    * "09:30 UTC" is therefore represented as:  09:30Z
    * "14:45:15 UTC" would be:  14:45:15Z
    *
    * Example of a valid combined date and time representation in UTC:
    * 2017-11-29T20:49:41Z
    *
    * NOTE:  The REGEX pattern used for validation of this type utilizes the ISO 8601 extended date and time format.
    *
    * The javaType to specify is tricky for the CIM primitive type called "DateTime".  Given that the
    * documentation in the CIM model for the class indicates that it can represent any of the date time
    * representations mentioned in the above comments we chose here to set the "javaType" to OffsetDateTime
     -->
    <xsl:param name="datetime_pattern">^(([0-9]{4})-(((02)-(0[1-9]|[1][0-9]|2[0-9]))|((0[4689]|(11))-(0[1-9]|[1][0-9]|2[0-9]|(30)))|((0[13578]|(1[02]))-(0[1-9]|[1][0-9]|2[0-9]|(3[0-1])))))T((2[0-3]|[01][0-9])((:([0-5][0-9])((:([0-5][0-9])(([.][0-9]+)?)?)?)?)?)|(24)((:(00)((:(00)(([.][0]+)?)?)?)?)?))(Z|[+-](2[0-3]|[01][0-9])(:([0-5][0-9]))?)$</xsl:param>
	<xsl:param name="datetime_javatype">java.time.OffsetDateTime</xsl:param>
	<!-- <xsl:param name="datetime_javatype">java.time.LocalDateTime</xsl:param> -->

    <!--
    * TIME:
    * Type used to express either a local time (no timezone offset), UTC time zone, or local timezone relative UTC
    * in ISO 8601 standard extended time format.
    *
    * When no UTC relation information is given with a time representation, the time is assumed to be
    * in local time. While it may be safe to assume local time when communicating in the same time zone,
    * it is ambiguous when used in communicating across different time zones. Even within a single geographic
    * time zone, some local times will be ambiguous if the region observes daylight saving time. It is usually
    * preferable to indicate a time zone (zone designator) using the ISO 8601 standard's notation.
    *
    * A local time (not timezone offset) is specified as: "hh:mm:ss.sss"
    * UTC time zone is specified as: "hh:mm:ss.sssZ"
    * A local timezone relative UTC is specified as: "hh:mm:ss.sss±hh:mm"
    *
    * Example of a valid time representation of 8:49:41pm:
    * 20:49:41
    * 20:49:41Z
    * 14:49:41-06:00
    *
    * The following times all refer to the same moment:
    * 18:30Z
    * 22:30+04
    * 11:30-07:00
    * 15:00-03:30
    *
    * NOTE:  The REGEX pattern used for validation of this type utilizes the ISO 8601 extended time format.
    *
    *  The javaType to specify is tricky for the CIM primitive type called "Time".  Given that the
    *  documentation in the CIM model for the class indicate that it can represent any of the time
    *  representations mentioned in the above comments we chose here to set the "javaType" to OffsetTime
     -->
    <xsl:param name="time_pattern">^((2[0-3]|[01][0-9])((:([0-5][0-9])((:([0-5][0-9])(([.][0-9]+)?)?)?)?)?)|(24)((:(00)((:(00)(([.][0]+)?)?)?)?)?))(Z|[+-](2[0-3]|[01][0-9])(:([0-5][0-9]))?)$</xsl:param>
	<xsl:param name="time_javatype">java.time.OffsetDateTime</xsl:param>
	<!-- <xsl:param name="time_javatype">java.time.LocalTime</xsl:param>  -->

    <!--
    * DURATION:
    * Duration as "PnYnMnDTnHnMnS" which conforms to ISO 8601, where nY expresses a number of years,
    * nM a number of months, nD a number of days. The letter T separates the date expression from the
    * time expression and, after it, nH identifies a number of hours, nM a number of minutes and nS
    * a number of seconds. The number of seconds could be expressed as a decimal number, but all other
    * numbers are integers.
     -->
    <xsl:param name="duration_pattern">^P(?!$)(([0-9]+Y)|([0-9]+[,\.][0-9]+Y$))?(([0-9]+M)|([0-9]+[,\.][0-9]+M$))?(([0-9]+W)|([0-9]+[,\.][0-9]+W$))?(([0-9]+D)|([0-9]+[,\.][0-9]+D$))?(T(?=[0-9])(([0-9]+H)|([0-9]+[,\.][0-9]+H$))?(([0-9]+M)|([0-9]+[,\.][0-9]+M$))?([0-9]+([,\.][0-9]+)?S)?)??$</xsl:param>
	<xsl:param name="duration_javatype">java.time.Duration</xsl:param>

    <!--
    * MONTHDAY:
    * MonthDay format, which conforms with XSD data type gMonthDay.
    *
    * Description:
    * The value space of xsd:gMonthDay is the period of one calendar day recurring each calendar year
    * (such as the third of April); its lexical space follows the ISO 8601 syntax for such periods
    * with an optional time zone.
    *
    * When needed, days are reduced to fit in the length of the months, so - - 02-29 would occur on the
    * 28th of February of nonleap years.
    *
    * Restrictions:
    * The period (one year) and the duration (one day) are fixed, and no calendars other than Gregorian are supported.
    *
    * Example of valid values:
    *  - -05-01
    *  - -11-01Z
    *  - -11-01+02:00
    *  - -11-01-04:00
    *  - -11-15
    *  - -02-29
    *
    * The following values are invalid:
    *  -01-30- (the format must be - -MM-DD)
    *  - -01-35 (the day part is out of range)
    *  - -1-5 (the leading zeros are missing)
    *  or
    *  01-15 (the leading - - are missing)
    -->
    <xsl:param name="monthday_pattern">^(--(((02)-(0[1-9]|[1][0-9]|2[0-9]))|((0[4689]|(11))-(0[1-9]|[1][0-9]|2[0-9]|(30)))|((0[13578]|(1[02]))-(0[1-9]|[1][0-9]|2[0-9]|(3[0-1])))))$</xsl:param>
	<xsl:param name="monthday_javatype">java.time.MonthDay</xsl:param>

    <xsl:template name="generate_properties">
        <xsl:choose>
            <xsl:when test="a:SuperType">
                <xsl:variable name="supertype_name" select="a:SuperType/@name" />
                <xsl:for-each select="/*/node()[@name = $supertype_name]">
                  <!--
                		IMPORTANT:  When generating Java classes using jsonschema2pojo this XSLT generates a "special" JSON schema that
                		is represented a bit differently than the standard JSON schema used to validate payloads. Specifically, by
                		commenting out the call below we ensure that we do not duplicate generating attributes from the parent classes
                    into the subclass as well. In this way jsonschema2pojo will generate Java classes that will properly contain
                    attributes as part of the class that owns them.
                	-->
                    <!-- <xsl:call-template name="generate_properties" /> -->
                </xsl:for-each>
                <xsl:apply-templates select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

	<xsl:template name="required_properties">
		<xsl:choose>
	   		<xsl:when test="a:SuperType">
	   			<xsl:variable name="supertype_name" select="a:SuperType/@name" />
	   			<xsl:for-each select="/*/node()[@name = $supertype_name]">
	   				<xsl:call-template name="required_properties" />
	   			</xsl:for-each>
				<xsl:for-each select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice">
					<xsl:if test="@minOccurs &gt;= 1">
						<item>"<xsl:value-of select="@name" />", </item>
					</xsl:if>
				</xsl:for-each>
	    	</xsl:when>
	    	<xsl:otherwise>
				<xsl:for-each select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice">
					<xsl:if test="@minOccurs &gt;= 1">
						<item>"<xsl:value-of select="@name" />", </item>
					</xsl:if>
				</xsl:for-each>
	    	</xsl:otherwise>
	    </xsl:choose>
	</xsl:template>

    <xsl:template name="generate_required_properties_list">
		<xsl:variable name="super" select="a:SuperType" />
	 	<xsl:choose>
			<xsl:when test="$super">
				<xsl:variable name="required_properties">
					<xsl:call-template name="required_properties" />
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="string-length($required_properties) > 0">
						<list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
							<xsl:choose>
								<!-- We add a '@type' property to the required array if this is a ComplexType class that is used in a Choice... -->
								<xsl:when test="self::a:ComplexType and $generate_jsonschema2pojo_annotations = 'false' and /*//node()[local-name() = 'Choice']/node()[local-name() = 'Instance' and @type = current()/@name]">
									<item>"@type", <xsl:value-of select="substring($required_properties, 1, string-length($required_properties) - 2)" /></item>
								</xsl:when>
								<xsl:otherwise>
									<item><xsl:value-of select="substring($required_properties, 1, string-length($required_properties) - 2)" /></item>
								</xsl:otherwise>
							</xsl:choose>
						</list>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="self::a:ComplexType and $generate_jsonschema2pojo_annotations = 'false'">
							<!-- We add a '@type' property to the required array if this ComplexType class is used in a Choice... -->
							<xsl:if test="/*//node()[local-name() = 'Choice']/node()[local-name() = 'Instance' and @type = current()/@name]">
								<list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
									<item>"@type"</item>
								</list>
							</xsl:if>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="count(a:Complex[@minOccurs >= 1]|a:Enumerated[@minOccurs >= 1]|a:SimpleEnumerated[@minOccurs >= 1]|a:Simple[@minOccurs >= 1]|a:Domain[@minOccurs >= 1]|a:Instance[@minOccurs >= 1]|a:Reference[@minOccurs >= 1]|a:Choice[@minOccurs >= 1]) > 0">
						<list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
							<xsl:if test="self::a:ComplexType and $generate_jsonschema2pojo_annotations = 'false'">
								<!-- We add a '@type' property to the required array if this ComplexType class is used in a Choice... -->
								<xsl:if test="/*//node()[local-name() = 'Choice']/node()[local-name() = 'Instance' and @type = current()/@name]">
									<item>"@type"</item>
								</xsl:if>
							</xsl:if>
							<xsl:for-each select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice">
								<xsl:if test="@minOccurs &gt;= 1">
									<item>"<xsl:value-of select="@name" />"</item>
								</xsl:if>
							</xsl:for-each>
						</list>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="self::a:ComplexType and $generate_jsonschema2pojo_annotations = 'false'">
							<!-- We add a '@type' property to the required array if this ComplexType class is used in a Choice... -->
							<xsl:if test="/*//node()[local-name() = 'Choice']/node()[local-name() = 'Instance' and @type = current()/@name]">
								<list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
									<item>"@type"</item>
								</list>
							</xsl:if>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

    <!-- These patterns are derived and driven off of the CIM date/time types within the CIM model -->
    <xsl:template name="pattern">
        <xsl:param name="xstype" />
        <xsl:choose>
            <xsl:when test="$xstype = 'dateTime'">
                <xsl:value-of select="$datetime_pattern" />
            </xsl:when>
            <xsl:when test="$xstype = 'date'">
                <xsl:value-of select="$date_pattern" />
            </xsl:when>
            <xsl:when test="$xstype = 'time'">
                <xsl:value-of select="$time_pattern" />
            </xsl:when>
            <xsl:when test="$xstype = 'duration'">
                <xsl:value-of select="$duration_pattern" />
            </xsl:when>
            <xsl:when test="$xstype = 'gMonthDay'">
                <xsl:value-of select="$monthday_pattern" />
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="type">
        <xsl:param name="xstype" />
        <xsl:choose>
            <xsl:when test="$xstype = 'string'">string</xsl:when>
            <xsl:when test="$xstype = 'normalizedString'">string</xsl:when>
            <xsl:when test="$xstype = 'token'">string</xsl:when>
            <xsl:when test="$xstype = 'NMTOKEN'">string</xsl:when>
            <xsl:when test="$xstype = 'anyURI'">string</xsl:when>
            <xsl:when test="$xstype = 'NCName'">string</xsl:when>
            <xsl:when test="$xstype = 'Name'">string</xsl:when>
            <xsl:when test="$xstype = 'integer' or $xstype = 'int' or $xstype = 'short' or $xstype = 'long'">integer</xsl:when>
            <xsl:when test="$xstype = 'float' or $xstype = 'double' or $xstype = 'decimal' or $xstype = 'number'">number</xsl:when>
            <xsl:when test="$xstype = 'boolean'">boolean</xsl:when>
            <xsl:when test="$xstype = 'dateTime'">string</xsl:when>
            <xsl:when test="$xstype = 'date'">string</xsl:when>
            <xsl:when test="$xstype = 'time'">string</xsl:when>
            <xsl:when test="$xstype = 'duration'">string</xsl:when>
            <xsl:when test="$xstype = 'gMonthDay'">string</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$xstype" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ============================================================================================================ -->
    <!-- START THE ROOT ELEMENT OF THE PROFILE: "top-level" Catalog element                                           -->
    <!-- ============================================================================================================ -->

	<!-- IMPORTANT:  This use of the XSL 1.0 key is needed to ensure we create only a single unique *Ref class for each class type.  -->
	<xsl:key name="references" match="a:Reference" use="@type"/>

    <xsl:template match="a:Catalog">
        <!-- the top level template -->
        <document>
            <list begin="{{" indent="     " delim="," end="}}">
                <item>"$id": "<xsl:value-of select="substring-before($baseURI, $envelope)" /><xsl:value-of select="$envelope" />.schema.json"</item>
                <item>"$schema": "<xsl:value-of select="$schema_draft_version" />"</item>
                <item>"title": "<xsl:value-of select="$envelope" />"</item>
                <item>"description": "<xsl:call-template name="annotate"/>"</item>
                <item>"namespace": "<xsl:value-of select="$baseURI" />"</item>
                <item>"type": "object"</item>
				<xsl:if test="$generate_jsonschema2pojo_annotations = 'true'">
					<xsl:choose>
						<xsl:when test="self::a:Reference">
							<item>"javaType": "<xsl:call-template name="java_type_ref"><xsl:with-param name="type" select="@type"/></xsl:call-template>"</item>
						</xsl:when>
						<xsl:otherwise>
							<item>"javaType": "<xsl:value-of select="concat($package_prefix, '.', 'Dependency')"/>"</item>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
                <item>"additionalProperties": false</item>

                <!-- Now compute the number of required properties and if > 0 we add a "required" JSON element... -->
                <xsl:variable name="properties" select="a:Root"/>
                <xsl:variable name="required_properties_count" select="count($properties[@minOccurs &gt;= 0]/@minOccurs)"/>

                <!-- IF the message declares root elements we add a properties section to include them -->
                <xsl:if test="a:Root">
                    <list begin="&quot;properties&quot;: {{" indent="    " delim="," end="}}">
						<!-- We cycle through all classes -->
						<!-- We temporarily are excluding SimpleType(s) while using the "reduced" Domain types
						     and when we reintroduce them we should change the for-each to include them.
						<xsl:for-each select="a:ComplexType|a:CompoundType|a:EnumeratedType|a:SimpleType"> -->
						<list begin="&quot;{$envelope}&quot;: {{" indent="     " end="}}">
							<item>"$ref": "#/$defs/<xsl:value-of select="$envelope" />"</item>
						</list>
						<xsl:for-each select="a:ComplexType|a:CompoundType|a:EnumeratedType">
							<list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
								<item>"$ref": "#/definitions/<xsl:value-of select="@name" />"</item>
							</list>
						</xsl:for-each>
					</list>
                    <!-- Determine if a JSON "required" element is needed in the schema;
                         otherwise just terminate with a closing bracket -->
                    <xsl:if test="count(a:Root[@minOccurs >= 1]) > 0">
                        <!--  Now generate the "required" JSON element based on minOccurs >=1  -->
                        <list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
                            <!-- First, we cycle through "Enumerated" attributes -->
                            <xsl:for-each select="a:Root[@minOccurs >= 1]">
                                <item>"<xsl:value-of select="@name" />"</item>
                            </xsl:for-each>
                        </list>
                    </xsl:if>
                </xsl:if>

                <list begin="&quot;$defs&quot;: {{" indent="     " delim="," end="}}">
                	<!--  generates the top-level root payload properties definitions -->
					<list begin="&quot;{$envelope}&quot;: {{" indent="    " delim="," end="}}">
						<item>"title": "<xsl:value-of select="$envelope" />"</item>
						<item>"description": "Base type..."</item>
						<item>"javaType": "<xsl:value-of select="concat($package_prefix, '.', $envelope)" />"</item>
						<item>"type": "object"</item>
						<list begin="&quot;properties&quot;: {{" indent="    " delim="," end="}}">
							<!-- We cycle through all "Root" classes -->
							<xsl:apply-templates select="a:Root"/>
						</list>
					</list>

                    <!-- <xsl:apply-templates select="a:Message" /> -->
                    <xsl:apply-templates mode="declare" />
                    <xsl:for-each select=".//a:Reference[generate-id() = generate-id(key('references',@type)[1])]">
                        <xsl:call-template name="generate_ref_class"/>
                    </xsl:for-each>
                </list>
            </list>
        </document>
    </xsl:template>

    <xsl:template match="a:Root">
        <!--  generates the top-level root payload properties definitions -->
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
                        <item>"$ref": "#/$defs/<xsl:value-of select="substring-after(@baseClass,'#')" />"</item>
                    </list>
                    <xsl:if test="@minOccurs &gt;= 1">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <item>"$ref": "#/$defs/<xsl:value-of select="substring-after(@baseClass,'#')" />"</item>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>
    <!-- ============================================================================================================ -->
    <!-- END ROOT ELEMENT PROCESSING                                                                                  -->
    <!-- ============================================================================================================ -->


    <!-- ============================================================================================================ -->
    <!-- START SECTION:  (Complex, ComplexType, Root, & CompoundType(s) TYPE DEFINITION templates)                    -->
    <!-- Templates that match on class types & that map to JSON subschema definitions in the schema "$defs"     -->
    <!-- ============================================================================================================ -->

    <xsl:template match="a:Root" mode="declare">
        <list begin="&quot;{substring-after(@baseClass,'#')}&quot;: {{" indent="    " delim="," end="}}">
            <xsl:call-template name="type_definition"/>
        </list>
    </xsl:template>

    <xsl:template match="a:ComplexType|a:CompoundType" mode="declare">
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <xsl:call-template name="type_definition"/>
        </list>
    </xsl:template>

    <!--  Generates a nested JSON object definition.  Equivalent to an XSD inline anonymous complex type declaration  -->
    <xsl:template match="a:Complex">
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <item>"description": "<xsl:call-template name="annotate"/>"</item>
                    <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
                        <xsl:call-template name="type_definition"/>
                    </list>
                    <xsl:if test="@minOccurs &gt;= 1">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="type_definition"/>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

    <!--  Generates a nested JSON enum definition.  Equivalent to an XSD inline anonymous enumerated type declaration  -->
    <xsl:template match="a:SimpleEnumerated">
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <item>"description": "<xsl:call-template name="annotate"/>"</item>
                    <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
                        <!-- declares an enumerated type -->
                        <xsl:call-template name="type_definition_header">
                            <xsl:with-param name="type">string</xsl:with-param>
                        </xsl:call-template>
                        <list begin="&quot;enum&quot;: [" indent="    " delim="," end="]">
                            <xsl:apply-templates select="a:EnumeratedValue"/>
                        </list>
                    </list>
                    <xsl:if test="@minOccurs &gt;= 1">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <!-- declares an enumerated type -->
                    <xsl:call-template name="type_definition_header">
                        <xsl:with-param name="type">string</xsl:with-param>
                    </xsl:call-template>
                    <list begin="&quot;enum&quot;: [" indent="    " delim="," end="]">
                        <xsl:apply-templates select="a:EnumeratedValue"/>
                    </list>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

    <xsl:template match="a:EnumeratedType" mode="declare">
        <!-- declares an enumerated type -->
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <xsl:call-template name="type_definition_header">
                <xsl:with-param name="type">string</xsl:with-param>
            </xsl:call-template>
            <list begin="&quot;enum&quot;: [" indent="    " delim="," end="]">
                <xsl:apply-templates select="a:EnumeratedValue"/>
            </list>
        </list>
    </xsl:template>

    <xsl:template match="a:EnumeratedValue">
        <!-- declares one value within an enumerated type -->
        <item>"<xsl:value-of select="@name" />"</item>
    </xsl:template>
    <!-- ============================================================================================================ -->
    <!-- END SECTION:  Complex, ComplexType, Root, & CompoundType(s) TYPE DEFINITION templates                        -->
    <!-- ============================================================================================================ -->


    <!-- ============================================================================================================ -->
    <!-- START SECTION:  type_definition and type_definition_header templates                                         -->
    <!-- ============================================================================================================ -->
    <xsl:template name="type_definition_header">
        <xsl:param name="type" />
        <xsl:choose>
            <xsl:when test="self::a:Root">
                <item>"title": "<xsl:value-of select="substring-after(@baseClass, '#')" />"</item>
            </xsl:when>
            <xsl:otherwise>
                <item>"title": "<xsl:value-of select="@name" />"</item>
            </xsl:otherwise>
        </xsl:choose>
        <item>"description": "<xsl:call-template name="annotate"/>"</item>
        <xsl:choose>
            <xsl:when test="self::a:SimpleType">
                <!--  SimpleType(s) only contain a dataType attribute representing modelReference -->
                <item>"modelReference": "<xsl:value-of select="@dataType" />"</item>
            </xsl:when>
            <xsl:when test="self::a:EnumeratedType|self::a:ComplexType|self::a:Root">
                <!--  ComplexType(s) and Root(s) only contain a baseClass attribute representing modelReference -->
                <item>"modelReference": "<xsl:value-of select="@baseClass" />"</item>
            </xsl:when>
            <xsl:otherwise>
                <!--  Everything else is assumed to be an attribute or association (i.e. a JSON schema "property") -->
                <xsl:if test="@baseProperty">
                    <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
		<xsl:if test="$generate_jsonschema2pojo_annotations = 'true'">
			<xsl:choose>
				<xsl:when test="self::a:Reference">
					<item>"javaType": "<xsl:call-template name="java_type_ref"><xsl:with-param name="type" select="@type"/></xsl:call-template>"</item>
				</xsl:when>
				<xsl:when test="self::a:Complex">
					<item>"javaType": "<xsl:call-template name="java_type_anonymous"/>"</item>
				</xsl:when>
				<xsl:when test="self::a:SimpleEnumerated">
					<xsl:variable name="fully-qualified-name"><xsl:call-template name="java_type_anonymous"/></xsl:variable>
					<xsl:variable name="suffix" select="substring($fully-qualified-name, string-length($fully-qualified-name) - 3)" />
					<xsl:choose>
						<xsl:when test="$suffix != 'Kind' and $suffix != 'Type'">
							<item>"javaType": "<xsl:call-template name="java_type_anonymous"/>KindType"</item>
						</xsl:when>
						<xsl:when test="$suffix = 'Kind'">
							<item>"javaType": "<xsl:call-template name="java_type_anonymous"/>Type"</item>
						</xsl:when>
						<xsl:otherwise>
							<item>"javaType": "<xsl:call-template name="java_type_anonymous"/>"</item>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
                <xsl:when test="self::a:EnumeratedType">
					<xsl:variable name="fully-qualified-name"><xsl:call-template name="java_type_standard"/></xsl:variable>
					<xsl:variable name="suffix" select="substring($fully-qualified-name, string-length($fully-qualified-name) - 3)" />
					<xsl:choose>
						<xsl:when test="$suffix != 'Kind' and $suffix != 'Type'">
							<item>"javaType": "<xsl:call-template name="java_type_standard"/>KindType"</item>
						</xsl:when>
						<xsl:when test="$suffix = 'Kind'">
							<item>"javaType": "<xsl:call-template name="java_type_standard"/>Type"</item>
						</xsl:when>
						<xsl:otherwise>
							<item>"javaType": "<xsl:call-template name="java_type_standard"/>"</item>
						</xsl:otherwise>
					</xsl:choose>
                </xsl:when>
				<xsl:otherwise>
					<item>"javaType": "<xsl:call-template name="java_type_standard"/>"</item>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:variable name="super" select="a:SuperType" />
			<xsl:if test="$super">
				<list begin="&quot;extends&quot;: {{" indent="    " delim="," end="}}">
                    <item>"$ref": "#/$defs/<xsl:value-of select="$super/@name" />"</item>
                    <!--
                     <item>"$ref": "#/$defs/<xsl:value-of select="@type" />"</item>
					<item>"<xsl:call-template name="java_superclass"><xsl:with-param name="super_name" select="$super/@name"/></xsl:call-template>"</item>-->
				</list>
			</xsl:if>
		</xsl:if>
        <item>"type": "<xsl:value-of select="$type" />"</item>
    </xsl:template>

    <!-- General template that provides the basic structure for a JSON subschema object definition -->
    <xsl:template name="type_definition">

        <xsl:call-template name="type_definition_header">
            <xsl:with-param name="type">object</xsl:with-param>
        </xsl:call-template>

        <item>"additionalProperties": false</item>

        <xsl:variable name="super" select="a:SuperType" />

        <list begin="&quot;properties&quot;: {{" indent="    " delim="," end="}}">
			<xsl:if test="$generate_jsonschema2pojo_annotations = 'false'">
				<!-- We add a '@type' property to the properties list for this class if it is used in a Choice... -->
				<xsl:if test="/*//node()[local-name() = 'Choice']/node()[(local-name() = 'Instance' or local-name() = 'Reference') and @type = current()/@name]">
					<list begin="&quot;@type&quot;: {{" indent="    " delim="," end="}}">
						<item>"const" : "<xsl:value-of select="@name"/>"</item>
					</list>
				</xsl:if>
			</xsl:if>
            <xsl:choose>
                <xsl:when test="$super">
                    <xsl:call-template name="generate_properties" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </list>

        <xsl:call-template name="generate_required_properties_list"/>

    </xsl:template>
    <!-- ============================================================================================================ -->
    <!-- END SECTION:  type_definition and type_definition_header templates                                           -->
    <!-- ============================================================================================================ -->


    <!-- ============================================================================================================ -->
    <!-- START SECTION:  (ComplexType, Root, and CompoundType attribute & association templates)                      -->
    <!-- Templates that match on attributes/associations and map to JSON properties in a JSON object "properties"     -->
    <!-- ============================================================================================================ -->
    <xsl:template match="a:Simple">
        <xsl:param name="type">
            <xsl:call-template name="type">
                <xsl:with-param name="xstype" select="@xstype"/>
            </xsl:call-template>
        </xsl:param>
		<xsl:param name="java_type">
			<xsl:call-template name="java_type">
				<xsl:with-param name="xstype" select="@xstype"/>
			</xsl:call-template>
		</xsl:param>
        <xsl:param name="pattern">
            <xsl:call-template name="pattern">
                <xsl:with-param name="xstype" select="@xstype"/>
            </xsl:call-template>
        </xsl:param>
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <item>"description": "<xsl:call-template name="annotate"/>"</item>
            <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
						<xsl:if test="$generate_jsonschema2pojo_annotations = 'true'">
							<xsl:if test="$java_type != ''">
								<item>"javaType": "<xsl:value-of select="$java_type"/>"</item>
							</xsl:if>
						</xsl:if>
                        <item>"type": "<xsl:value-of select="$type" />"</item>
                    </list>
                    <xsl:if test="@minOccurs &gt;= 1">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
					<xsl:if test="$generate_jsonschema2pojo_annotations = 'true'">
						<xsl:if test="$java_type != ''">
							<item>"javaType": "<xsl:value-of select="$java_type"/>"</item>
						</xsl:if>
					</xsl:if>
                    <item>"type": "<xsl:value-of select="$type"/>"</item>
                    <xsl:if test="$pattern != ''">
                        <item>"pattern": "<xsl:value-of select="$pattern"/>"</item>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

	 <!-- This is what should be used when we are creating a designated subschema for a:Domain class.  For now we are mapping purely to a JSON primitive type and have broken out a separate template to handle a:Domain.
    <xsl:template match="a:Instance|a:Domain|a:Enumerated">
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <xsl:call-template  name="array_body" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template  name="standard_body" />
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>
	-->

	<!-- This template should be removed when we do not want to generate a "reduced" CIMDatatype.  -->
	<xsl:template match="a:Instance|a:Enumerated">
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <xsl:call-template  name="array_body" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template  name="standard_body" />
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

	<!-- This template should be removed when we do not want to generate a "reduced" CIMDatatype -->
	<xsl:template match="a:Domain">
	    <xsl:param name="type">
            <xsl:call-template name="type">
                <xsl:with-param name="xstype" select="@xstype"/>
            </xsl:call-template>
        </xsl:param>
        <xsl:param name="pattern">
            <xsl:call-template name="pattern">
                <xsl:with-param name="xstype" select="@xstype"/>
            </xsl:call-template>
        </xsl:param>
		<list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <item>"description": "<xsl:call-template name="annotate"/>"</item>
            <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs > 1">
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
                        <item>"type": "<xsl:value-of select="$type" />"</item>
                    </list>
                    <xsl:if test="@minOccurs > 0">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <item>"type": "<xsl:value-of select="$type"/>"</item>
                    <xsl:if test="$pattern != ''">
                        <item>"pattern": "<xsl:value-of select="$pattern"/>"</item>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

    <xsl:template match="a:Reference">
        <xsl:variable name="ref_name" select="@name"/>
        <list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
            <!--  Check to see if we need a JSON array (i.e. maxOccurs > 1) -->
            <xsl:choose>
                <xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
                    <item>"description": "<xsl:call-template name="annotate"/>"</item>
                    <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
                    <item>"type": "array"</item>
                    <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
                        <!-- <xsl:call-template  name="ref_body" />  -->
                        <item>"$ref": "#/$defs/<xsl:value-of select="concat(@type, 'Ref')" />"</item>
                    </list>
                    <xsl:if test="@minOccurs &gt;= 1">
                        <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
                    </xsl:if>
                    <xsl:if test="@maxOccurs != 'unbounded'">
                        <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <item>"description": "<xsl:call-template name="annotate"><xsl:with-param name="notes" select="../node()[@name = $ref_name]"/></xsl:call-template>"</item>
                    <item>"modelReference": "<xsl:value-of select="../node()[@name = $ref_name]/@baseProperty" />"</item>
                    <item>"$ref": "#/$defs/<xsl:value-of select="concat(@type, 'Ref')" />"</item>
                </xsl:otherwise>
            </xsl:choose>
        </list>
    </xsl:template>

    <!-- This type of Choice attribute generates a nested JSON object definition.  Equivalent to an XSD inline anonymous complex type declaration  -->
    <xsl:template match="a:Choice">
		<list begin="&quot;{@name}&quot;: {{" indent="    " delim="," end="}}">
			<xsl:variable name="super" select="a:SuperType[1]" />

			<item>"description": "<xsl:call-template name="annotate"/>"</item>
			<xsl:if test="@baseProperty">
				<item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
			</xsl:if>
			<item>"$comment": "Options for the choice corresponding to the '<xsl:value-of select="@name" />' property."</item>

			<xsl:choose>
				<xsl:when test="@maxOccurs = 'unbounded' or @maxOccurs &gt; 1">
					<item>"type": "array"</item>
					<list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
						<xsl:choose>
							<xsl:when test="count(self::a:Choice[./a:Reference]) > 0">
								<item>"$ref": "#/$defs/<xsl:value-of select="concat(@inheritanceBaseType, 'Ref')" />"</item>
							</xsl:when>
							<xsl:otherwise>
								<item>"$ref": "#/$defs/<xsl:value-of select="@inheritanceBaseType" />"</item>
							</xsl:otherwise>
						</xsl:choose>
					</list>
					<xsl:if test="@minOccurs &gt;= 1">
						<item>"minItems": <xsl:value-of select="@minOccurs" /></item>
					</xsl:if>
					<xsl:if test="@maxOccurs != 'unbounded'">
						<item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="count(self::a:Choice[./a:Reference]) > 0">
							<item>"$ref": "#/$defs/<xsl:value-of select="concat(@inheritanceBaseType, 'Ref')" />"</item>
						</xsl:when>
						<xsl:otherwise>
							<item>"$ref": "#/$defs/<xsl:value-of select="@inheritanceBaseType" />"</item>
						</xsl:otherwise>
					</xsl:choose>
					<!--
                    <list begin="&quot;oneOf&quot;: [" indent="    " delim="," end="]">
						<xsl:for-each select="a:Complex|a:Enumerated|a:SimpleEnumerated|a:Simple|a:Domain|a:Instance|a:Reference|a:Choice">
							<list begin="{{" indent="    " delim="," end="}}">
								<xsl:choose>
									<xsl:when test="self::a:Reference">
										<item>"$ref": "#/$defs/<xsl:value-of select="concat(@type, 'Ref')" />"</item>
									</xsl:when>
									<xsl:otherwise>
										<item>"$ref": "#/$defs/<xsl:value-of select="@type" />"</item>
									</xsl:otherwise>
								</xsl:choose>
							</list>
						</xsl:for-each>
					</list>
					-->
                </xsl:otherwise>
			</xsl:choose>
		</list>
	</xsl:template>

    <xsl:template name="generate_ref_class">
        <xsl:variable name="ref_name" select="@type"/>
        <list begin="&quot;{@type}Ref&quot;: {{" indent="    " delim="," end="}}">
            <item>"description": "The unique 'by reference' Ref type definition for the <xsl:value-of select="@type" /> class."</item>
            <item>"modelReference": "<xsl:value-of select="@baseClass" />"</item>
			<xsl:if test="$generate_jsonschema2pojo_annotations = 'true'">
				<item>"javaType": "<xsl:call-template name="java_type_ref"><xsl:with-param name="type" select="@type"/></xsl:call-template>"</item>
			</xsl:if>
            <item>"type": "object"</item>
            <list begin="&quot;properties&quot;: {{" indent="    " delim="," end="}}">
                <list begin="&quot;ref&quot;: {{" indent="    " delim="," end="}}">
                    <item>"type": "string"</item>
                </list>
                <list begin="&quot;referenceType&quot;: {{" indent="    " delim="," end="}}">
                    <item>"type": "string"</item>
                </list>
            </list>
            <!--  Always "required" for ref  -->
            <list begin="&quot;required&quot;: [" indent="    " delim="," end="]">
                <item>"ref"</item>
            </list>
        </list>
    </xsl:template>

    <xsl:template name="array_body">
        <item>"description": "<xsl:call-template name="annotate"/>"</item>
        <xsl:if test="@baseProperty">
            <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
        </xsl:if>
        <item>"type": "array"</item>
        <list begin="&quot;items&quot;: {{" indent="    " delim="," end="}}">
            <item>"$ref": "#/$defs/<xsl:value-of select="@type" />"</item>
        </list>
        <xsl:if test="@minOccurs &gt;= 1">
            <item>"minItems": <xsl:value-of select="@minOccurs" /></item>
        </xsl:if>
        <xsl:if test="@maxOccurs != 'unbounded'">
            <item>"maxItems": <xsl:value-of select="@maxOccurs" /></item>
        </xsl:if>
    </xsl:template>

    <xsl:template name="standard_body">
        <xsl:variable name="description">
            <xsl:call-template name="annotate"/>
        </xsl:variable>
        <xsl:if test="$description != ''">
            <item>"description": "<xsl:value-of select="$description" />"</item>
        </xsl:if>
        <xsl:if test="@baseProperty">
            <item>"modelReference": "<xsl:value-of select="@baseProperty" />"</item>
        </xsl:if>
        <item>"$ref": "#/$defs/<xsl:value-of select="@type" />"</item>
    </xsl:template>
    <!-- ============================================================================================================ -->
    <!-- END SECTION:  ComplexType, Root, & CompoundType(s) attribute/association templates                           -->
    <!-- ============================================================================================================ -->

    <xsl:template name="annotate">
        <xsl:variable name="notes" select="a:Comment|a:Note"/>
        <!-- generate human readable annotation -->
        <list begin="" indent="" delim=" " end="">
            <xsl:for-each select="$notes">
                <!-- Remove double quotes to eliminate broken comments, etc. -->
                <item><xsl:value-of select="translate(., '&quot;', '')" /></item>
            </xsl:for-each>
        </list>
    </xsl:template>

    <xsl:template match="text()">
        <!--  dont pass text through  -->
    </xsl:template>

    <xsl:template match="node()" mode="declare">
        <!-- dont pass any defaults in declare mode -->
    </xsl:template>

</xsl:stylesheet>
