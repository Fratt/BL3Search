<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="url" uri="http://www.exalead.com/jspapi/url" %>
<%@ taglib prefix="config" uri="http://www.exalead.com/jspapi/config" %>
<%@ taglib prefix="render" uri="http://www.exalead.com/jspapi/render" %>
<%@ taglib prefix="i18n" uri="http://www.exalead.com/jspapi/i18n" %>
<%@ taglib prefix="widget" uri="http://www.exalead.com/jspapi/widget" %>
<%@ taglib prefix="search" uri="http://www.exalead.com/jspapi/search" %>

<render:import varFeeds="feeds" />

<config:getOption var="dateFacet" name="dateFacet" defaultValue="lastmodifieddate" />

<widget:widget varCssId="cssId">
	<widget:header>
		<config:getOption name="title" defaultValue="Timeline" />
	</widget:header>
	<widget:content>
		<div style="text-align:center">
			<canvas id="timelineChart" width="650" height="200"></canvas>
		</div>
	</widget:content>
</widget:widget>

<render:renderScript>

	// Read the parameter from the URL (http://stackoverflow.com/a/21151913)
	var get_params = function(search_string) {
	  var parse = function(params, pairs) {
	    var pair = pairs[0];
	    var parts = pair.split('=');
	    var key = decodeURIComponent(parts[0]);
	    var value = decodeURIComponent(parts.slice(1).join('='));
	    if (typeof params[key] === "undefined") {
	      params[key] = value;
	    } else {
	      params[key] = [].concat(params[key], value);
	    }
	    return pairs.length == 1 ? params : parse(params, pairs.slice(1))
	  }
	  return search_string.length == 0 ? {} : parse({}, search_string.substr(1).split('&'));
	}
	
	var params = get_params(location.search);
	
	// Turn a string into an array with the string
	var makeSureArray = function(x) {
		if (typeof x == 'string') {
			return [x];
		}
		return x;
	}
	
	// Parse the currently active refinements
	var getRefines = function(params) {
		var refines = new Array();
		var	allRefines = makeSureArray(params["cloudview.r"]);
		var removedRefines = makeSureArray(params["cloudview.zr"]);
				
		for (var i=0; i < allRefines.length; i++) {
			var refine = allRefines[i];
			// If this refine has not been removed later, we want it
			if($.inArray(refine, removedRefines) == -1) {
				refines.push(refine);
			}
		}
		return refines;
	}
	
	var goToUrl = function(currentUrl, type, date) {
		// Year
		if (type == "y") {
			location.href = currentUrl + "&cloudview.r=f/${dateFacet}/" + date;
		// Year + month
		} else if (type == "m") {
			var month = date.substring(0, 2);
			var year = date.substring(3);
			location.href = currentUrl + "&cloudview.r=f/${dateFacet}/" + year + "/" + month;
		} else if (type == "d") {
			var day = date.substring(0, 2);
			var month = date.substring(3, 5);
			var year = date.substring(6);
			location.href = currentUrl + "&cloudview.r=f/${dateFacet}/" + year + "/" + month + "/" + day;
		}
		 //alert("TODO: We have to refine by date: " + date + " in url : " + currentUrl);
	}
	
	var globalData;

	
	// We load the values using ajax, and initialize the graph when we got them
	$.ajax({
		url : '<c:url value="/" />timeline/get',
		dataType: "json",
		success: function (data, textStatus, jqXHR) {
		
			globalData = data;
		
			// We parse the data	
			var values = data.values;
			var labels = new Array();
			var data = new Array();
			for (var i=0; i < values.length; i++) {
				var value = values[i];
				labels.push(value.name);
				data.push(value.value);
			}
		
			// We initialize the graph
			var canvas = $("#timelineChart").get(0);
			var ctx = $("#timelineChart").get(0).getContext("2d");
			var data = {
			    labels: labels,
			    datasets: [
			        {
			            label: "Created",
			            fillColor: "rgba(151,187,205,0.5)",
			            strokeColor: "rgba(151,187,205,0.8)",
			            highlightFill: "rgba(151,187,205,0.75)",
			            highlightStroke: "rgba(151,187,205,1)",
			            data: data
			        }
			    ]
			};
			var myBarChart = new Chart(ctx).Bar(data, { });
			canvas.onclick = function(evt) {
		    	var activeBars = myBarChart.getBarsAtEvent(evt);
		     	goToUrl(location.href, globalData.type, activeBars[0].label);	
			};
			
		},
		error: function () {
			alert('Error while loading the timeline!');
			// TODO : We hide the widget instead!
		},
		type: "GET",
		cache:false,
		data: { "query" : "test", "facet" : "${dateFacet}", "r" : makeSureArray(params["cloudview.r"]), "zr" : makeSureArray(params["cloudview.zr"]) }
	});
	
	
</render:renderScript>