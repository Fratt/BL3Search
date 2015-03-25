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

<widget:widget varCssId="widgetId">
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
	
	var isDateRefine = function(key, value, facet) {
		return (key == "cloudview.r" || key == "cloudview.zr") && value.indexOf("f/" + facet) === 0;
	}
	
	var goToUrl = function(currentUrl, type, date) {
	
		// We remove all the currently active refinements on the facet
		var questionMark = currentUrl.indexOf("?");
		var url = currentUrl.substring(0, questionMark+1);
		var params = get_params(currentUrl.substring(questionMark));
		for(var key in params) {
		    var value = params[key];
			if (typeof value == 'string') {
				if (!isDateRefine(key, value, "${dateFacet}")) {
					url += key + "=" + encodeURIComponent(value) + "&";
				}
			} else {
				for (var i=0; i < value.length; i++) {
					if (!isDateRefine(key, value, "${dateFacet}")) {
						url += key + "=" + encodeURIComponent(value[i]) + "&";
					}
				}
			}
		}
		
		// We build the url		
		location.href = url + "cloudview.r=" + "f/${dateFacet}/" + date;
	}
	
	var generateLabel = function(date, type) {
		if (type == "y") {  // yyyy
			return date;
			
		// Year + month
		} else if (type == "m") {   // yyyy/mm
			return date.substring(5, 7) + "." + date.substring(0, 4);
		
		// Year + month + day
		} else if (type == "d") {   // yyyy/mm/dd
			return date.substring(8) + "." + date.substring(5, 7) + "." + date.substring(2, 4);
		}
		
		// Should never happen
		alert("Invalid date! Date=" + date + ", type=" + type);
		return date;
	}

	var globalJson;
	var labelToDate = {};
	
	// We load the values using ajax, and initialize the graph when we got them
	$.ajax({
		url : '<c:url value="/" />timeline/get',
		dataType: "json",
		success: function (json, textStatus, jqXHR) {
		
			globalJson = json;
		
			// We parse the data	
			var values = json.values;
			var labels = new Array();
			var data = new Array();
			for (var i=0; i < values.length; i++) {
				var value = values[i];
				// We generate a label for the graph
				var label = generateLabel(value.date, json.type);
				// We push the label and add the date<->label to the mapping
				labels.push(label);
				labelToDate[label] = value.date;
				data.push(value.count);
			}
			
			if (labels.length <= 1 && json.type == "d") {
				$("#${widgetId}").slideUp();
				return;
			}
			
		
			// We initialize the graph
			var canvas = $("#timelineChart").get(0);
			var ctx = $("#timelineChart").get(0).getContext("2d");
			var chartData = {
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
			var myBarChart = new Chart(ctx).Bar(chartData, { });
			canvas.onclick = function(evt) {
		    	var activeBars = myBarChart.getBarsAtEvent(evt);
		     	goToUrl(location.href, globalJson.type, labelToDate[activeBars[0].label]);
			};
			
		},
		error: function () {
			alert('Error while loading the timeline!');
			$("#${widgetId}").slideUp();
		},
		type: "GET",
		cache:false,
		data: { "query" : params["q"], "facet" : "${dateFacet}", "r" : makeSureArray(params["cloudview.r"]), "zr" : makeSureArray(params["cloudview.zr"]) }
	});
	
	
</render:renderScript>