<!---

    Mach-II - A framework for object oriented MVC web applications in CFML
    Copyright (C) 2003-2010 GreatBizTools, LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.

	As a special exception, the copyright holders of this library give you
	permission to link this library with independent modules to produce an
	executable, regardless of the license terms of these independent
	modules, and to copy and distribute the resultant executable under
	the terms of your choice, provided that you also meet, for each linked
	independent module, the terms and conditions of the license of that
	module.  An independent module is a module which is not derived from
	or based on this library and communicates with Mach-II solely through
	the public interfaces* (see definition below). If you modify this library,
	but you may extend this exception to your version of the library,
	but you are not obligated to do so. If you do not wish to do so,
	delete this exception statement from your version.


	* An independent module is a module which not derived from or based on
	this library with the exception of independent module components that
	extend certain Mach-II public interfaces (see README for list of public
	interfaces).

Author: Peter J. Farrell (peter@mach-ii.com)
$Id$

Created version: 1.9.0
Updated version: 1.9.0

Notes:
--->
<cfcomponent
	displayname="FileMatcher"
	extends="AntPathMatcher"
	output="false"
	hint="Provides path matching using ANT style path selectors on a file system.">

	<!---
	PROPERTIES
	--->
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="FileMatcher" output="false"
		hint="Initializes the path pattern matcher.">
		<cfargument name="pathSeparator" type="string" required="false" />
		
		<cfset var temp = "" />
		
		<!--- Determine if _queryDeleteRow_java should be used and reassign to common function --->
		<cftry>
			<cfset temp = QueryNew("name", "VarChar") />
			<cfset QueryAddRow(temp, 2) />
			<!--- Use two rows of data or QueryDeleteRow fails on OpenBD 1.3 --->
			<cfset QuerySetCell(temp, "name", "Mach-II", 1) />
			<cfset QuerySetCell(temp, "name", "Framework", 2) />
			<cfset QueryDeleteRow(temp, 1) />
			
			<cfcatch type="any">
				<cfset variables.queryDeleteRow = variables._queryDeleteRow_java />
			</cfcatch>
		</cftry>
		
		<cfset super.init(argumentCollection=arguments) />

		<cfreturn this />
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="match" access="public" returntype="query" output="false"
		hint="Matches the passed path against the pattern according to the matching strategy.">
		<cfargument name="pattern" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfargument name="removeRootPath" type="string" required="false" default="" />
		<cfargument name="excludePatterns" type="array" required="false" default="#ArrayNew(1)#" />
		
		<cfset var pathResults = "" />
		<cfset var pathResultsRecordCount = 0 />
		<cfset var recurse = false />
		<cfset var i = 0 />
		<cfset var j = 0 />

		<!--- Clean up the pattern --->
		<cfset arguments.pattern = pathClean(arguments.pattern) />
		<cfset arguments.removeRootPath = pathClean(arguments.removeRootPath) />
		
		<!--- Only recurse if there is a ** in the pattern to save on performance --->
		<cfif FindNoCase("**", arguments.pattern)>
			<cfset recurse = true />
		</cfif>
		
		<!--- Find possible candidates --->
		<cfdirectory name="pathResults" 
			action="list" 
			directory="#arguments.path#"
			sort="name"
			recurse="#recurse#" />
		
		<!--- Add modified path column --->
		<cfset QueryAddColumn(pathResults, "modifiedPath", "VarChar", ArrayNew(1)) />
		<cfset QueryAddColumn(pathResults, "fullPath", "VarChar", ArrayNew(1)) />

		<!---
		Build possible paths by removing the root path if requested. This option 
		is offered because cfinclude cannot use absolute file paths
		I know two loop that are similar is harder to maintain, but it's better performance
		--->
		<cfif Len(arguments.removeRootPath)>
			<cfloop from="#pathResults.recordcount#" to="1" index="i" step="-1">
				<cfif pathResults.type[i] EQ "file">
					<cfset pathResults.directory[i] =  ReplaceNoCase(pathResults.directory[i], "\", "/", "all") />
					<cfset pathResults.fullPath[i] = pathResults.directory[i] & "/" & pathResults.name[i] />
					<cfset pathResults.modifiedPath[i] =  ReplaceNoCase(pathResults.directory[i], arguments.removeRootPath, "", "one") & "/" & pathResults.name[i] />
				<cfelse>
					<cfset queryDeleteRow(pathResults, i) />
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop from="#pathResults.recordcount#" to="1" index="i" step="-1">
				<cfif pathResults.type[i] EQ "file">
					<cfset pathResults.directory[i] =  ReplaceNoCase(pathResults.directory[i], "\", "/", "all") />
					<cfset pathResults.fullPath[i] = pathResults.directory[i] & "/" & pathResults.name[i] />
					<cfset pathResults.modifiedPath[i] = pathResults.fullPath[i] />
				<cfelse>
					<cfset queryDeleteRow(pathResults, i) />
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- N.B. At this point, all paths use "/" as the path separator regardless of OS --->
		
		<!--- Remove page view paths that match exclude paths or patterns 
			(except go in reverse because we may delete from the query)--->
		<cfif ArrayLen(arguments.excludePatterns)>
			<cfset arguments.excludePatterns = cleanExcludePatterns(arguments.excludePatterns) />
			<cfloop from="#pathResults.recordcount#" to="1" index="i" step="-1">
				<cfloop from="1" to="#ArrayLen(arguments.excludePatterns)#" index="j">
					<!--- If pattern and pattern matches or if exact path --->
					<cfif arguments.excludePatterns[j] EQ pathResults.modifiedPath[i]
						OR (isPattern(arguments.excludePatterns[j]) 
						AND super.match(arguments.excludePatterns[j], pathResults.modifiedPath[i]))>
						<!---
						If a pattern is found, delete and break out of the inner loop (short-circuit)
						We're using the underlying Java method
						--->
						<cfset queryDeleteRow(pathResults, i) />
						<cfbreak />
					</cfif>
				</cfloop>
			</cfloop>
		</cfif>
		
		<cfset pathResultsRecordCount = pathResults.recordcount />
		
		<!---
			Looks for all the results that match the input pattern
			Loop from last to row 2 since we have to get around a QueryDeleteRow() bug in OpenBD 1.3
			when only one row of data remains in the query.
		--->
		<cfif pathResults.recordCount GTE 2>
			<cfloop from="#pathResults.recordCount#" to="2" index="i" step="-1">
				<cfif NOT super.match(arguments.pattern, pathResults.modifiedPath[i])>
					<cfset queryDeleteRow(pathResults, i) />
				</cfif>
			</cfloop>
		</cfif>
		
		<!--- Get around a QueryDeleteRow() bug in OpenBD 1.3 when only one row of data remains in the query. --->
		<cfif pathResults.recordCount GTE 1 AND NOT super.match(arguments.pattern, pathResults.modifiedPath[1])>
			<cfif pathResults.recordCount EQ 1>
				<cfset pathResults = QueryNew("name,size,type,directory,dateLastModified,attributes,modifiedPath,fullPath") />
			<cfelse>
				<cfset queryDeleteRow(pathResults, 1) />
			</cfif>
		</cfif>
		
		<cfreturn pathResults />
	</cffunction>

	<cffunction name="matchStart" access="public" returntype="void" output="false"
		hint="Not planned for implementation.">
		<cfabort showerror="This method is not planned to be implemented." />
	</cffunction>

	<cffunction name="pathClean" access="public" returntype="string" output="false"
		hint="Cleans paths so all paths use a uniform delimiter.">
		<cfargument name="path" type="string" required="true" />
		<cfreturn ReplaceNoCase(arguments.path, "\", "/", "all") />
	</cffunction>
	
	<cffunction name="extractPathWithoutPattern" access="public" returntype="string" output="false"
		hint="Extract the path base (the part before the pattern starts) from a string.">
		<cfargument name="string" type="string" required="true" />
		
		<cfset var parts = ListToArray(arguments.string, "/") />
		<cfset var result = "" />
		<cfset var i = 0 />
		
		<cfloop from="1" to="#ArrayLen(parts)#" index="i">
			<cfif NOT isPattern(parts[i])>
				<cfset result = ListAppend(result, parts[i], "/") />
			</cfif>
		</cfloop>
		
		<cfif arguments.string.startsWith("/")>
			<cfset result = "/" & result>
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<!---
	PROTECTED FUNCTIONS
	--->
	<cffunction name="_queryDeleteRow_java" access="private" returntype="void" output="false"
		hint="Deletes a row from a query.">
		<cfargument name="query" type="query" required="true" />
		<cfargument name="rowNumber" type="numeric" required="true" />
		<!--- Query rows in the Java methods start at 0 so we need to offset the row number to delete --->
		<cfset arguments.query.removeRows(arguments.rowNumber - 1,  1) />
	</cffunction>
	
	<cffunction name="cleanExcludePatterns" access="private" returntype="array" output="false"
		hint="Cleans the exclude pattern paths.">
		<cfargument name="excludePatterns" type="array" required="true"
			hint="The exclude patterns to clean." />
			
		<cfset var cleanedExcludePatterns = ArrayNew(1) />
		<cfset var i = 0 />
		
		<cfloop from="1" to="#ArrayLen(arguments.excludePatterns)#" index="i">
			<cfset ArrayAppend(cleanedExcludePatterns, pathClean(arguments.excludePatterns[i])) />
		</cfloop>
		
		<cfreturn cleanedExcludePatterns />
	</cffunction>

</cfcomponent>