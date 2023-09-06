<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pmd="http://pmd.sourceforge.net/report/2.0.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/">
    <testsuites>
      <xsl:for-each select="//pmd:file">
        <xsl:variable name="filename" select="@name"/>
        <testsuite name="PMD - {$filename}">
          <xsl:for-each select=".//pmd:violation">
            <xsl:variable name="message" select="normalize-space(.)"/>
            <xsl:variable name="rule" select="@rule"/>
            <xsl:variable name="priority" select="@priority"/>
            <xsl:variable name="line" select="@beginline"/>
            <xsl:variable name="column" select="@begincolumn"/>
            <xsl:variable name="endline" select="@endline"/>
            <xsl:variable name="endcolumn" select="@endcolumn"/>
            <xsl:variable name="package" select="@package"/>
            <xsl:variable name="class" select="@class"/>
            <xsl:variable name="method" select="@method"/>
            <xsl:variable name="externalInfoUrl" select="@externalInfoUrl"/>
            <xsl:variable name="ruleset" select="@ruleset"/>
            <testcase name="{$rule}" classname="{$filename}" time="0">
              <failure message="{$message}" type="{$priority}" line="{$line}" column="{$column}" endline="{$endline}" endcolumn="{$endcolumn}" package="{$package}" class="{$class}" method="{$method}" externalInfoUrl="{$externalInfoUrl}" ruleset="{$ruleset}">
                <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                <xsl:value-of select="$message"/>
                <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
              </failure>
            </testcase>
          </xsl:for-each>
        </testsuite>
      </xsl:for-each>
    </testsuites>
  </xsl:template>

</xsl:stylesheet>
