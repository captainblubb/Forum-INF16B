<!-- @author Marco Dauber, Philipp Seitz, Morten Terhart
  -- * Displays a list of posts supplying certain filter criteria
  -- * received through a GET request from the URL
--> 

<%-- Import Statements --%>
<%@ page import="java.util.Set" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.lang.*" %>
<%@ page import="de.dhbw.StudentForum.Posting" %>
<%@ page import="de.dhbw.StudentForum.User" %>
<%@ page import="java.text.DateFormat" %>
<%@ page import="java.text.ParseException" %>
<%@ taglib uri = "http://java.sun.com/jsp/jstl/core" prefix = "c" %>

<%!
    // Uniform declarations of used parameter identifiers
    private static final String POST_ID_PARAMETER      = "postid";
    private static final String USER_ID_PARAMETER      = "userid";
    private static final String LATEST_PARAMETER       = "latest";
    private static final String SEARCH_TERM_PARAMETER  = "searchterm";
    private static final String MAX_POSTINGS_PARAMETER = "maxpostings";
    private static final String FORUM_ID_PARAMETER     = "forumid";
    private static final String TAG_ID_PARAMETER       = "tagid";
    private static final String MIN_DATE_PARAMETER     = "mindate";
    private static final String MAX_DATE_PARAMETER     = "maxdate";

    // Object instance to get access to the database
    private DAO databaseObject = new DAO();
%>

<%!
	// Private Postings constants and container for
	// applied parameters on the URL (either via
    // GET or POST request)
    private int postId = -1;
    private int forumId = -1;
    private int tagId = -1;
    private int userId = -1;
    private int maxPostings = 100;
    private boolean latest = false;
    private Date minDate = null;
    private Date maxDate = null;

    // Collection of retrieved postings to iterate over
    // to display as list overview
    Set<Posting> postSelection = new HashSet<>();
%>

<%
    // Dummy elements
    String dummyAuthor = "Max Mustermann";

    int index = 0;
    Posting p1 = new Posting(index++);
    p1.setTitle("Brauche Hilfe bei Doppelintegralen in Mathe");
    p1.setWhenPosted(new Date());
    String[] tags1 = { "Mathe", "Integral" };
    p1.setTags(tags1);
    postSelection.add(p1);
%>

<%
    // --- Parameter Handling ---
    // Accessing the Parameters
    String postIdString      = request.getParameter(POST_ID_PARAMETER);
    String tagIdString       = request.getParameter(TAG_ID_PARAMETER);
    String userIdString      = request.getParameter(USER_ID_PARAMETER);
    String forumIdString     = request.getParameter(FORUM_ID_PARAMETER);
    String latestString      = request.getParameter(LATEST_PARAMETER);
    String maxPostingsString = request.getParameter(MAX_POSTINGS_PARAMETER);
    String searchTermString  = request.getParameter(SEARCH_TERM_PARAMETER);
    String minDateString     = request.getParameter(MIN_DATE_PARAMETER);
    String maxDateString     = request.getParameter(MAX_DATE_PARAMETER);

    // Validating and parsing the parameters to the consigned
    // data types such as integer, boolean or dates
    DateFormat format = DateFormat.getDateInstance();
    try {
        if (postIdString != null) {
            postId = Integer.parseInt (postIdString);
        }
        if (tagIdString != null) {
            tagId = Integer.parseInt (tagIdString);
        }
        if (userIdString != null) {
            userId = Integer.parseInt (userIdString);
        }
        if (forumIdString != null) {
            forumId = Integer.parseInt (forumIdString);
        }
        if (maxPostingsString != null) {
            maxPostings = Integer.parseInt (maxPostingsString);
        }
        if (latestString != null) {
            latest = Boolean.parseBoolean (latestString);
        }
        if (minDateString != null) {
            minDate = format.parse (minDateString);
        }
        if (maxDateString != null) {
            maxDate = format.parse (maxDateString);
        }
    } catch(NumberFormatException exc) {
        System.out.println("Could not perform integer parsing");
        exc.printStackTrace();
        return;
    } catch(ParseException exc) {
        System.out.println("Could not parse the date received by the request");
        exc.printStackTrace();
        return;
    }

    // Action Decision Investigation
    // The following if statements represent various use cases for the postings
    // component inside the INF16B forum. Depending on the assigned parameters
    // they decide which kind of postings to load from the database. Therefore
    // all the parameters are checked against an inequality of `null`.
    if (searchTermString != null && minDateString != null && maxDateString != null && tagIdString != null && forumIdString != null) {
        // Extended Search Request
        extendedSearchRequest (searchTermString, forumId, tagId, minDate, maxDate);
    } else if (latestString != null && maxPostingsString != null && maxPostings == 8) {
        // Top 8 Postings on the homepage
        selectTop8Postings ();
    } else if (searchTermString != null) {
        // Simple Search Request from the Header line
        simpleSearchRequest (searchTermString);
    } else if (forumIdString != null) {
        // Postings of a specific forum
        selectForumPostings(forumId);
    } else if (tagIdString != null) {
        // Postings of a specific tag
        selectTagPostings(tagId);
    } else if (userIdString != null) {
        // Postings of a specific user
        selectUserPostings(userId);
    } else {
        // If none of these use cases is matched, create an empty set
        // and display nothing
        postSelection = new HashSet<Posting>();
    }
%>

<%!
    // Methods used by the Postings component

    /**
     * Selects the latest 8 postings out of the database to show
     * on the index page
     */
    private void selectTop8Postings() {
        latest = true;
        Collections.addAll(postSelection, databaseObject.getLatestPostings());
    }

    /**
     * Applies the given parameters as query to the database object and selects
     * the posts matching the criteria
     * @param searchTerm the string that is searched after
     * @param forumId the identifier of thfe forum which is searched in
     * @param tagId the identifier of the tag the posts must contain
     * @param minDate the minimal date specifying the lower border of creation date
     * @param maxDate the maximal date specifying the upper border of creation date
     */
    private void extendedSearchRequest(String searchTerm, int forumId, int tagId, Date minDate, Date maxDate) {
        postSelection = databaseObject.searchPostings(searchTerm, forumId, tagId, minDate, maxDate);
    }

    /**
     * Initializes the postSelection with postings containing the search term
     * @param searchTerm the specific search term to look after
     */
    private void simpleSearchRequest(String searchTerm) {
        postSelection = databaseObject.searchPostings(searchTerm);
    }

    /**
     * Initializes the postSelection with all postings appearing in a specific forum
     * @param forumId the id of the specific forum
     */
    private void selectForumPostings(int forumId) {
        postSelection = databaseObject.selectPostingsByForum(forumId);
    }

    /**
     * Initializes the postSelection with all postings attached with a specific tag
     * @param tagId the id of the specific tag
     */
    private void selectTagPostings(int tagId) {
        postSelection = databaseObject.selectPostingsByTag(tagId);
    }

    /**
     * Initializes the postSelection with all postings submitted by a specific user
     * @param userId the id of the specific user
     */
    private void selectUserPostings(int userId) {
        postSelection = databaseObject.selectPostingsByUser(userId);
    }
%>

<c:forEach items="${postSelection}" var="currentPost" end="${maxPostings}">
    <a href="posting.jsp?postid=${currentPost.getId()}">
        <div class="post">
            <div class="profilbild">
		    <img src="${((User) databaseObject.getUserById(currentPost.getUserId()).getImgUrl()}" height="60" width="60" />
            </div>
            <div>
                <div>INF16B &gt; Mathe</div>
                <span class="author"> <%= dummyAuthor %> </span>
                <span class="date"> ${currentPost.getWhenPosted()} </span>

                <h1><i> ${currentPost.getTitle()} </i></h1>

                <c:forEach items="${currentPost.getTags()}" var="tag">
                    <span class="tagbox">${tag}</span>
                </c:forEach>

                <span class="answer"> 200 Antworten </span>
            </div>
        </div>
    </a>
</c:forEach>
