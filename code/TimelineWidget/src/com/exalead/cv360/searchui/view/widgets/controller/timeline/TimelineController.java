package com.exalead.cv360.searchui.view.widgets.controller.timeline;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.context.ServletContextAware;

import com.exalead.cv360.config.CM;
import com.exalead.cv360.config.NotificationListener;
import com.exalead.cv360.customcomponents.CustomComponent;
import com.exalead.cv360.searchui.config.MashupConfigurationProvider;
import com.exalead.cv360.searchui.configuration.v10.MashupUI;
import com.exalead.cv360.searchui.mvc.model.GCTMashupConfigurationLoader;
import com.exalead.cv360.searchui.mvc.model.MashupConfiguration;
import com.exalead.cv360.searchui.security.MashupSecurityManager;
import com.exalead.cv360.searchui.security.SecurityModel;
import com.exalead.cv360.service.messages.Notification;
import com.exalead.cv360.service.messages.NotifyConfigurationUpdate;
import com.exalead.searchapi.client.SearchAPIClient;
import com.exalead.searchapi.client.SearchAPIClientFactory;
import com.exalead.searchapi.xmlv10.client.Category;
import com.exalead.searchapi.xmlv10.client.CategoryGroup;
import com.exalead.searchapi.xmlv10.client.SearchAnswer;
import com.exalead.searchapi.xmlv10.client.SearchClient;
import com.exalead.searchapi.xmlv10.client.SearchClientException;
import com.exalead.searchapi.xmlv10.client.SearchQuery;

@Controller
@CustomComponent(displayName = "Timeline Controller")
public class TimelineController implements ServletContextAware, NotificationListener {
	
	private static final Logger logger = Logger.getLogger(TimelineController.class);
	private final static boolean ENABLE_SECURITY = false; // TODO : Change this !

	@RequestMapping(value = "/timeline/get", method = RequestMethod.GET)
	public void get(HttpServletRequest request, HttpServletResponse response, @RequestParam("query") String query, @RequestParam("facet") String facet, @RequestParam(value="r[]", required=false) String[] r, @RequestParam(value="zr[]", required=false) String[] zr) throws IOException {
		
		// TODO : We want the current user refinements too!
		// TODO : If no login, no results!
		
		HttpSession session = request.getSession();
		
		// We get the values we need from the Search API
		SearchAPIClient client = SearchAPIClientFactory.build("http://localhost:11010");
		SearchClient searchClient = client.searchClient("search-api");
		SearchQuery sq = new SearchQuery(query);
		sq.addParameter("hf", "0");
		sq.addParameter("synthesis_hits", "0");
		//sq.addParameter("f." + facet + ".max_depth", "1");
		sq.addParameter("f." + facet + ".sort", "alphanum");
		
		// We refine according to what we want
//		if (year != null) {
//			// If we want the months of this year..
//			if (month == null) {
//				sq.addParameter("r", "+f/" + facet + "/" + year);
//			// If we want the days of this month
//			} else {
//				sq.addParameter("r", "+f/" + facet + "/" + year + "/" + month);
//			}
//		}
		
		// We set the current user refines
		StringBuilder neededFacets = new StringBuilder(facet);
		if (r != null) {
			for (String refine : r) {
				sq.addParameter("r", refine);
				int beforeFacet = refine.indexOf("f/");
				int afterFacet = refine.indexOf("/", beforeFacet+3);
				neededFacets.append("," + refine.substring(beforeFacet+2, afterFacet));
			}
		}
		if (zr != null) {
			for (String refine : zr) {
				sq.addParameter("zr", refine);
				int beforeFacet = refine.indexOf("f/");
				int afterFacet = refine.indexOf("/", beforeFacet+3);
				neededFacets.append("," + refine.substring(beforeFacet+2, afterFacet));
			}
		}

		sq.addParameter("use_logic_facets", neededFacets.toString());  // TODO .properties
		
		// Security tokens
		if (ENABLE_SECURITY) {
			List<String> tokens = getSecurityTokens(session);
			sq.addParameter("enforce_security", "true");
			for (String token : tokens) {
				sq.addParameter("security_token", token);
			}
		}
		
		// We compute !
		SearchAnswer sa = null;
		try {
			sa = searchClient.getResults(sq);
		} catch (SearchClientException e) {
			logger.error(String.format("Error while obtaining the timeline values for the query \"{}\"", sq));
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			return;
		}
		
		// We extract the values
		JSONObject json = new JSONObject();
		JSONArray array = new JSONArray();
		CategoryGroup cg = sa.getCategoryGroup(facet);
		String type = null;
		if (cg != null) {
			List<Category> years = cg.getCategories();
			// If there's more than 1 years, we display the years
			if (years.size() > 1) {
				for (Category year : years) {
					array.put(generateValue(year.getTitle(), Integer.toString(year.getCount())));
				}
				type = "y";
				
			// If there's only one year, we display the months or the days
			} else if (years.size() == 1) {
				Category year = years.get(0);
				List<Category> months = year.getCategories();
				// If there's more than 1 months, we display the months
				if (months.size() > 1) {
					for (Category month : months) {
						array.put(generateValue(year.getTitle() + "/" + month.getTitle(), Integer.toString(month.getCount())));
					}
					type = "m";
				// If there's only one month, we display the days
				} else if (months.size() == 1) {
					Category month = months.get(0);
					List<Category> days = month.getCategories();
					for (Category day : days) {
						array.put(generateValue(year.getTitle() + "/" + month.getTitle() + "/" + day.getTitle(), Integer.toString(day.getCount())));
					}
					type = "d";
				}
			}
		}
		json.put("values", array);
		json.put("type", type);
		json.put("query", sq.toString());
		
		response.setContentType("text/json");
		response.setStatus(HttpServletResponse.SC_OK);
		response.setCharacterEncoding("UTF-8");
		response.getOutputStream().write(json.toString().getBytes());
		response.flushBuffer();
	}
	
//	private String last(String string, int length) {
//		if (string != null && string.length() > length) {
//			return string.substring(string.length() - length);
//		}
//		return string;
//	}
	
	private List<String> getSecurityTokens(HttpSession session) {
		if (MashupSecurityManager.getInstance().isLoggedIn(session)) {
			SecurityModel sModel = MashupSecurityManager.getSecurityModel(session);
			List<String> tokens = sModel.getTokens();
			if (sModel != null && tokens != null) {
				return tokens;
			}
		}
		return new ArrayList<String>();
	}

	private JSONObject generateValue(String date, String count) {
		JSONObject output = new JSONObject();
		output.put("date", date);
		output.put("count", count);
		return output;
	}


	/*
	@Override
	public void handleNotification(Notification arg0) throws Exception {		
	}

	@Override
	public void setServletContext(ServletContext arg0) {
	}
	*/	
	
	// ----------------------------- Exalead code -----------------------------

	private final ReadWriteLock configLock = new ReentrantReadWriteLock();
	@SuppressWarnings("unused")
	private MashupConfiguration gctMashupConfiguration = null;
	private void init() throws Exception {
		this.configLock.writeLock().lock();
		try {
			this.gctMashupConfiguration = GCTMashupConfigurationLoader.loadConfiguration();
		} finally {
			this.configLock.writeLock().unlock();
		}
	}
	@Override
	public void handleNotification(Notification notification) throws Exception {
		if (notification instanceof NotifyConfigurationUpdate) {
			if (((NotifyConfigurationUpdate) notification).isUpdated(MashupConfigurationProvider.getInstance().getApplicationId(), MashupUI.class)) {
				this.init();
			}
		}
	}
	@Override
	public void setServletContext(ServletContext arg0) {
		try {
			this.init();
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
		CM.registerNotificationListener(this);
	}


}
