package ch.elca.exalead.mashupui.feedtriggers;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.log4j.Logger;

import com.exalead.access.feedapi.AccessException;
import com.exalead.access.feedapi.Feed;
import com.exalead.access.feedapi.FeedTrigger;
import com.exalead.access.feedapi.QueryContext;
import com.exalead.access.feedapi.ResultFeed;

@com.exalead.cv360.customcomponents.CustomComponent(displayName="Swiss Date Trigger")
public class SwissDateFeedTrigger implements FeedTrigger {
	
	private static final Logger logger = Logger.getLogger(SwissDateFeedTrigger.class);

	private final static String[] DATE_PREFIX = new String[] { "after:", "before:", "date:" };
	private final static String SWISS_FORMAT = "dd.MM.yyyy";
	private final static String EXALEAD_FORMAT = "MM/dd/yyyy";

	@Override
	public Result beforeQuery(Feed feed, QueryContext context) throws AccessException {

		String[] criteriaValues = context.getQueryParams().get("q");
		if (criteriaValues.length > 0) {
			// WARNING :
			//   If you modify this code, keep in mind that quotes are not considered as delimiters !
			//   It means that source:"Some Source" will be split in two tokens ("source:\"Some" and "Source\""), not one!
			
			// We have to copy the immutable array...
	 		List<String> tokens = new ArrayList<String>(Arrays.asList(criteriaValues[0].split(" ")));
	 		
	 		// We then parse and change all the date params
	 		List<String> updatedTokens = new ArrayList<String>();
	 		for (String token : tokens) {
	 			updatedTokens.add(changeDateFormat(token, new SimpleDateFormat(SWISS_FORMAT), new SimpleDateFormat(EXALEAD_FORMAT)));
	 		}
			feed.overrideParameter(context, "q", Arrays.asList(new String[] { join(updatedTokens, " ") }));
		}
		return Result.CONTINUE;
	}
	
	private String changeDateFormat(String token, DateFormat sourceFormat, DateFormat destinationFormat) {
		for (String datePrefix : DATE_PREFIX) {
			if (token.startsWith(datePrefix)) {
				try {
					String date = token.substring(datePrefix.length());
					String newToken = datePrefix + destinationFormat.format(sourceFormat.parse(date));
					logger.info("Transformed \"" + token + "\" to \"" + newToken + "\"");
					return newToken;
				} catch (ParseException e) {
					// If the format is invalid, we don't change the token
					logger.error("Unable to parse the date contained in " + token, e);
					return token;
				}
			}
		}
		// If no prefix was found, we don't change the token
		return token;
	}

	private String join(List<String> tokens, String string) {
		StringBuilder acc = new StringBuilder();
		for (String token : tokens) {
			if (acc.length() > 0) {
				acc.append(" ");
			}
			acc.append(token);
		}
		return acc.toString();
	}

	@Override
	public Result afterQuery(Feed feed, QueryContext context, ResultFeed resultFeed) throws AccessException {
		return Result.CONTINUE;
	}


}
