<!---
License:
Copyright 2006 Mach-II Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright: Mach-II Corporation
Author: Ben Edwards (ben@ben-edwards.com)
$Id$

Created version: 1.1.0
Updated version: 1.5.0
--->
<cfcomponent 
	displayname="RedirectCommand" 
	extends="MachII.framework.Command"
	output="false"
	hint="An Command for redirecting.">
	
	<!---
	PROPERTIES
	--->
	<cfset variables.eventName = "" />
	<cfset variables.eventParameter = "" />
	<cfset variables.redirectPersistParameter = "" />
	<cfset variables.url = "" />
	<cfset variables.args = "" />
	<cfset variables.persist = "" />
	<cfset variables.persistArgs = "" />
	
	<!---
	INITIALIZATION / CONFIGURATION
	--->
	<cffunction name="init" access="public" returntype="RedirectCommand" output="false"
		hint="Used by the framework for initialization.">
		<cfargument name="eventName" type="string" required="true" />
		<cfargument name="eventParameter" type="string" required="true" />
		<cfargument name="redirectPersistParameter" type="string" required="true" />
		<cfargument name="url" type="string" required="false" default="" />
		<cfargument name="args" type="string" required="false" default="" />
		<cfargument name="persist" type="boolean" required="false" default="false" />
		<cfargument name="persistArgs" type="string" required="false" default="" />
		
		<cfset setEventName(arguments.eventName) />
		<cfset setEventParameter(arguments.eventParameter) />
		<cfset setRedirectPersistParameter(arguments.redirectPersistParameter) />
		<cfset setUrl(arguments.url) />
		<cfset setArgs(arguments.args) />
		<cfset setPersist(arguments.persist) />
		<cfset setPersistArgs(arguments.persistArgs) />
		
		<cfreturn this />
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="execute" access="public" returntype="boolean"
		hint="Executes the command.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
		<cfset var redirectUrl = makeRedirectUrl(arguments.event, arguments.eventContext) />
		<cflocation url="#redirectUrl#" addtoken="no" />
		
		<cfreturn true />
	</cffunction>
	
	<!---
	PROTECTED FUNCTIONS
	--->
	<cffunction name="makeRedirectUrl" access="private" returntype="string" output="false"
		hint="Assembles the redirect url.">
		<cfargument name="event" type="MachII.framework.Event" required="true" />
		<cfargument name="eventContext" type="MachII.framework.EventContext" required="true" />
		
		<cfset var redirectUrl = getUrl() />
		<cfset var redirectQueryStringParam = "" />
		<cfset var redirectQueryString = "" />
		<cfset var argNames = getArgs() />
		<cfset var argName = "" />
		
		<cfif redirectUrl EQ "">
			<cfset redirectUrl = "index.cfm" />
		</cfif>
		
		<!--- Attach the query string parameter. --->
		<cfif Find("?", redirectUrl) GT 0>
			<cfset redirectQueryStringParam = "&" />
		<cfelse>
			<cfset redirectQueryStringParam = "?" />
		</cfif>

		<!--- Attach the event name if defined --->
		<cfif getEventName() NEQ "">
			<cfset redirectQueryString = getEventParameter() & "=" & getEventName() />
		</cfif>
		
		<!--- Attach each additional arguments if it exists and is a simple value --->
		<cfloop index="argName" list="#argNames#" delimiters=",">
			<cfif arguments.event.isArgDefined(argName) AND IsSimpleValue(arguments.event.getArg(argName, ""))>
				<cfset redirectQueryString = redirectQueryString & "&" & argName & "=" & URLEncodedFormat(arguments.event.getArg(argName, "")) />
			</cfif>
		</cfloop>
		
		<cfif Len(redirectQueryString)>
			<cfreturn redirectUrl & redirectQueryStringParam & redirectQueryString />
		<cfelse>
			<cfreturn redirectUrl />		
		</cfif>
	</cffunction>
	
	<!---
	ACCESSORS
	--->
	<cffunction name="setEventName" access="private" returntype="void" output="false">
		<cfargument name="eventName" type="string" required="true" />
		<cfset variables.eventName = arguments.eventName />
	</cffunction>
	<cffunction name="getEventName" access="private" returntype="string" output="false">
		<cfreturn variables.eventName />
	</cffunction>
	
	<cffunction name="setEventParameter" access="private" returntype="void" output="false">
		<cfargument name="eventParameter" type="string" required="true" />
		<cfset variables.eventParameter = arguments.eventParameter />
	</cffunction>
	<cffunction name="getEventParameter" access="private" returntype="string" output="false">
		<cfreturn variables.eventParameter />
	</cffunction>
	
	<cffunction name="setRedirectPersistParameter" access="private" returntype="void" output="false">
		<cfargument name="redirectPersistParameter" type="string" required="true" />
		<cfset variables.redirectPersistParameter = arguments.redirectPersistParameter />
	</cffunction>
	<cffunction name="getRedirectPersistParameter" access="private" returntype="string" output="false">
		<cfreturn variables.redirectPersistParameter />
	</cffunction>
	
	<cffunction name="setUrl" access="private" returntype="void" output="false">
		<cfargument name="url" type="string" required="true" />
		<cfset variables.url = arguments.url />
	</cffunction>
	<cffunction name="getUrl" access="private" returntype="string" output="false">
		<cfreturn variables.url />
	</cffunction>
	
	<cffunction name="setArgs" access="private" returntype="void" output="false">
		<cfargument name="args" type="string" required="true" />
		<cfset variables.args = arguments.args />
	</cffunction>
	<cffunction name="getArgs" access="private" returntype="string" output="false">
		<cfreturn variables.args />
	</cffunction>
	
	<cffunction name="setPersist" access="private" returntype="void" output="false">
		<cfargument name="persist" type="boolean" required="true" />
		<cfset variables.persist = arguments.persist />
	</cffunction>
	<cffunction name="getPersist" access="private" returntype="boolean" output="false">
		<cfreturn variables.persist />
	</cffunction>
	
	<cffunction name="setPersistArgs" access="private" returntype="void" output="false">
		<cfargument name="persistArgs" type="string" required="true" />
		<cfset variables.persistArgs = arguments.persistArgs />
	</cffunction>
	<cffunction name="getPersistArgs" access="private" returntype="string" output="false">
		<cfreturn variables.persistArgs />
	</cffunction>

</cfcomponent>