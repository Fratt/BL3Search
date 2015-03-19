<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="url" uri="http://www.exalead.com/jspapi/url" %>
<%@ taglib prefix="config" uri="http://www.exalead.com/jspapi/config" %>
<%@ taglib prefix="render" uri="http://www.exalead.com/jspapi/render" %>
<%@ taglib prefix="i18n" uri="http://www.exalead.com/jspapi/i18n" %>
<%@ taglib prefix="widget" uri="http://www.exalead.com/jspapi/widget" %>

<render:import varFeeds="feeds" />

<widget:widget varCssId="cssId">
	<widget:header>
		<config:getOption name="title" defaultValue="Current Refinements _REV" />
	</widget:header>
	<widget:content>
		<search:forEachFacet var="facet" feeds="${feeds}">
			<!-- Include search banane! -->
			${facet}						
		</search:forEachFacet>
	</widget:content>
</widget:widget>