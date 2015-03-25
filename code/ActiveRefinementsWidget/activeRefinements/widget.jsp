<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="url" uri="http://www.exalead.com/jspapi/url" %>
<%@ taglib prefix="config" uri="http://www.exalead.com/jspapi/config" %>
<%@ taglib prefix="render" uri="http://www.exalead.com/jspapi/render" %>
<%@ taglib prefix="i18n" uri="http://www.exalead.com/jspapi/i18n" %>
<%@ taglib prefix="widget" uri="http://www.exalead.com/jspapi/widget" %>
<%@ taglib prefix="search" uri="http://www.exalead.com/jspapi/search" %>

<render:import varFeeds="feeds" />

<config:getOptions name="fullCategoryPath" var="fullCategoryPath" />

<%-- We check if any refinement is active --%>
<c:set var="activeRefinements" value="false" />
<search:forEachFacet var="facet" feeds="${feeds}">
	<search:forEachCategory var="category" root="${facet}" iterationMode="ALL">
		<search:getCategoryUrl var="categoryUrl" varClassName="className" category="${category}" />
		<c:if test="${className == 'refined'}">
			<c:set var="activeRefinements" value="true" />
		</c:if>
	</search:forEachCategory>
</search:forEachFacet>

<%-- If there's any refinement, we print the widget --%>
<c:if test="${activeRefinements}">
	<widget:widget varCssId="cssId">
		<widget:header>
			<config:getOption name="title" defaultValue="Active Refinements" />
		</widget:header>
		<widget:content>
			<div style="padding: 5px;">
				<ul>
					<search:forEachFacet var="facet" feeds="${feeds}">
						<search:getFacetLabel var="facetLabel" facet="${facet}" />
						<c:set var="displayFullCategoryPath" value="${fullCategoryPath.contains(facet.path)}" />
						<search:forEachCategory var="category" root="${facet}" iterationMode="ALL">
							<search:getCategoryUrl var="categoryUrl" varClassName="className" category="${category}" feeds="${feeds}" />
							<c:if test="${className == 'refined'}">
							
								<%-- We check if there's a sub-refinement too. If there is, we ignore this value. --%>  
								<c:set var="foundSubRefinement" value="false" />
								<search:forEachCategory var="subCategory" root="${category}" iterationMode="All">
									<search:getCategoryUrl var="subCategoryUrl" varClassName="subClassName" category="${subCategory}" feeds="${feeds}" />
									<c:if test="${subClassName == 'refined'}">
										<c:set var="foundSubRefinement" value="true" />
									</c:if>
								</search:forEachCategory>
							
								<%-- If not, we print it --%>
								<c:if test="${!foundSubRefinement}">
									<li>
										&nbsp;<b>${facetLabel}:</b>  <!-- ${facet.path} --> 
											<c:choose>
												<c:when test="${displayFullCategoryPath}">
													<span style="white-space:nowrap;">
														<%-- We split the path --%>
														<c:set var="pathParts" value="${fn:split(fn:substring(category.path, fn:length(facet.path)+1, fn:length(category.path)), '/')}" />
														<c:set var="currentPath" value="" />
														<c:forEach var="i" begin="0" end="${fn:length(pathParts) - 1}">
															<c:set var="currentPath" value="${currentPath}/${pathParts[i]}" />
															<search:getCategory var="subCategory" categoryPath="${facet.path}${currentPath}" facet="${facet}" iterationMode="ALL" />
															<search:getCategoryUrl var="subCategoryUrl" category="${subCategory}" feeds="${feeds}" />
															<a href="${subCategoryUrl}" class="refined"><search:getCategoryLabel category="${subCategory}" /></a><c:if test="${i != fn:length(pathParts) - 1}"><span style="color: #000; font-size: 11px; font-weight: bold;">&nbsp;&gt;</span></c:if>
														</c:forEach>
													</span>
												</c:when>
												<c:otherwise>
													<a href="${categoryUrl}" class="refined">
														<search:getCategoryLabel category="${category}" />
													</a>
												</c:otherwise>
											</c:choose>
									</li>
								</c:if>
							</c:if>
						</search:forEachCategory>
					</search:forEachFacet>
				</ul>
			</div>
		</widget:content>
	</widget:widget>
</c:if>