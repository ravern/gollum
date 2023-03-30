defmodule Gollum.GoogleTest do
  @moduledoc """
  Ported Google robots.txt library tests from
  https://github.com/google/robotstxt/blob/455b1583103d13ad88fe526bc058d6b9f3309215/robots_test.cc
  (up to line 763)

  Provides integration tests for Cache, Parser and Host.

  > This file tests the robots.txt parsing and matching code found in robots.cc
  > against the current Robots Exclusion Protocol (REP) RFC.
  > https://www.rfc-editor.org/rfc/rfc9309.html
  """
  use ExUnit.Case
  alias Gollum.Cache
  alias Gollum.Host

  setup do
    Cache.start_link(name: TestCache, fetcher: MockGoogle)
    :ok
  end

  @doc """
  Google-specific: system test.
  """
  @tag :skip
  test "GoogleOnly_SystemTest" do
    assert :ok = Cache.fetch("GoogleOnly_SystemTest-empty", name: TestCache)
    empty = Cache.get("GoogleOnly_SystemTest-empty", name: TestCache)
    assert :ok = Cache.fetch("GoogleOnly_SystemTest-disallow_foobot", name: TestCache)
    disallow_foobot = Cache.get("GoogleOnly_SystemTest-disallow_foobot", name: TestCache)

    # Empty robots.txt: everything allowed.
    assert :crawlable = Host.crawlable?(empty, "FooBot", "")
    # Empty user-agent to be matched: everything allowed.
    assert :crawlable = Host.crawlable?(disallow_foobot, "", "")
    #  Empty url: implicitly disallowed, see method comment for GetPathParamsQuery in robots.cc.
    assert :uncrawlable = Host.crawlable?(disallow_foobot, "FooBot", "")
    # All params empty: same as robots.txt empty, everything allowed.
    assert :crawlable = Host.crawlable?(empty, "", "")
  end

  @doc """
  Rules are colon separated name-value pairs. The following names are
  provisioned:
      user-agent: <value>
      allow: <value>
      disallow: <value>
  See REP RFC section "Protocol Definition".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.1

  Google specific: webmasters sometimes miss the colon separator, but it's
  obvious what they mean by "disallow /", so we assume the colon if it's
  missing.
  """
  @tag :skip
  test "ID_LineSyntax_Line" do
    assert :ok = Cache.fetch("ID_LineSyntax_Line-robotstxt_correct", name: TestCache)
    robotstxt_correct = Cache.get("ID_LineSyntax_Line-robotstxt_correct", name: TestCache)
    assert :ok = Cache.fetch("ID_LineSyntax_Line-robotstxt_incorrect", name: TestCache)
    robotstxt_incorrect = Cache.get("ID_LineSyntax_Line-robotstxt_incorrect", name: TestCache)
    assert :ok = Cache.fetch("ID_LineSyntax_Line-robotstxt_incorrect_accepted", name: TestCache)

    robotstxt_incorrect_accepted =
      Cache.get("ID_LineSyntax_Line-robotstxt_incorrect_accepted", name: TestCache)

    url = "http://foo.bar/x/y"

    assert :uncrawlable = Host.crawlable?(robotstxt_correct, "FooBot", url)
    assert :crawlable = Host.crawlable?(robotstxt_incorrect, "FooBot", url)
    assert :uncrawlable = Host.crawlable?(robotstxt_incorrect_accepted, "FooBot", url)
  end

  @doc """
  A group is one or more user-agent line followed by rules, and terminated
  by a another user-agent line. Rules for same user-agents are combined
  opaquely into one group. Rules outside groups are ignored.
  See REP RFC section "Protocol Definition".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.1
  """
  @tag :skip
  test "ID_LineSyntax_Groups" do
    assert :ok = Cache.fetch("ID_LineSyntax_Groups-robotstxt", name: TestCache)
    robotstxt = Cache.get("ID_LineSyntax_Groups-robotstxt", name: TestCache)

    url_w = "http://foo.bar/w/a"
    url_x = "http://foo.bar/x/b"
    url_y = "http://foo.bar/y/c"
    url_z = "http://foo.bar/z/d"
    url_foo = "http://foo.bar/foo/bar/"

    assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url_x)
    assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url_z)
    assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url_y)
    assert :crawlable = Host.crawlable?(robotstxt, "BarBot", url_y)
    assert :crawlable = Host.crawlable?(robotstxt, "BarBot", url_w)
    assert :uncrawlable = Host.crawlable?(robotstxt, "BarBot", url_z)
    assert :crawlable = Host.crawlable?(robotstxt, "BazBot", url_z)

    # Lines with rules outside groups are ignored.
    assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url_foo)
    assert :uncrawlable = Host.crawlable?(robotstxt, "BarBot", url_foo)
    assert :uncrawlable = Host.crawlable?(robotstxt, "BazBot", url_foo)
  end

  @doc """
  Group must not be closed by rules not explicitly defined in the REP RFC.
  See REP RFC section "Protocol Definition".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.1
  """
  test "ID_LineSyntax_Groups_OtherRules" do
    (
      assert :ok = Cache.fetch("ID_LineSyntax_Groups_OtherRules-sitemap", name: TestCache)
      sitemap = Cache.get("ID_LineSyntax_Groups_OtherRules-sitemap", name: TestCache)

      url = "http://foo.bar/"

      assert :uncrawlable = Host.crawlable?(sitemap, "FooBot", url)
      assert :uncrawlable = Host.crawlable?(sitemap, "BarBot", url)
    )
    (
      assert :ok = Cache.fetch("ID_LineSyntax_Groups_OtherRules-invalid_line", name: TestCache)
      invalid_line = Cache.get("ID_LineSyntax_Groups_OtherRules-invalid_line", name: TestCache)

      url = "http://foo.bar/"

      assert :uncrawlable = Host.crawlable?(invalid_line, "FooBot", url)
      assert :uncrawlable = Host.crawlable?(invalid_line, "BarBot", url)
    )
  end

  @doc """
  REP lines are case insensitive. See REP RFC section "Protocol Definition".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.1
  """
  test "ID_REPLineNamesCaseInsensitive" do
    assert :ok = Cache.fetch("ID_REPLineNamesCaseInsensitive-robotstxt_upper", name: TestCache)
    robotstxt_upper = Cache.get("ID_REPLineNamesCaseInsensitive-robotstxt_upper", name: TestCache)
    assert :ok = Cache.fetch("ID_REPLineNamesCaseInsensitive-robotstxt_lower", name: TestCache)
    robotstxt_lower = Cache.get("ID_REPLineNamesCaseInsensitive-robotstxt_lower", name: TestCache)
    assert :ok = Cache.fetch("ID_REPLineNamesCaseInsensitive-robotstxt_camel", name: TestCache)
    robotstxt_camel = Cache.get("ID_REPLineNamesCaseInsensitive-robotstxt_camel", name: TestCache)

    url_allowed = "http://foo.bar/x/y"
    url_disallowed = "http://foo.bar/a/b"

    assert :crawlable = Host.crawlable?(robotstxt_upper, "FooBot", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_lower, "FooBot", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_camel, "FooBot", url_allowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_upper, "FooBot", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_lower, "FooBot", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_camel, "FooBot", url_disallowed)
  end

  @doc """
  A user-agent line is expected to contain only [a-zA-Z_-] characters and must
  not be empty. See REP RFC section "The user-agent line".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.1
  """
  @tag :skip
  test "ID_VerifyValidUserAgentsToObey" do
    # not implemented in Gollum for now
  end

  @doc """
  User-agent line values are case insensitive. See REP RFC section "The
  user-agent line".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.1
  """
  @tag :skip
  test "ID_UserAgentValueCaseInsensitive" do
    assert :ok = Cache.fetch("ID_UserAgentValueCaseInsensitive-robotstxt_upper", name: TestCache)
    robotstxt_upper = Cache.get("ID_UserAgentValueCaseInsensitive-robotstxt_upper", name: TestCache)
    assert :ok = Cache.fetch("ID_UserAgentValueCaseInsensitive-robotstxt_lower", name: TestCache)
    robotstxt_lower = Cache.get("ID_UserAgentValueCaseInsensitive-robotstxt_lower", name: TestCache)
    assert :ok = Cache.fetch("ID_UserAgentValueCaseInsensitive-robotstxt_camel", name: TestCache)
    robotstxt_camel = Cache.get("ID_UserAgentValueCaseInsensitive-robotstxt_camel", name: TestCache)

    url_allowed = "http://foo.bar/x/y"
    url_disallowed = "http://foo.bar/a/b"

    assert :crawlable = Host.crawlable?(robotstxt_upper, "Foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_lower, "Foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_camel, "Foo", url_allowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_upper, "Foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_lower, "Foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_camel, "Foo", url_disallowed)
    assert :crawlable = Host.crawlable?(robotstxt_upper, "foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_lower, "foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_camel, "foo", url_allowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_upper, "foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_lower, "foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_camel, "foo", url_disallowed)
  end

  @doc """
  User-agent line values are case insensitive. See REP RFC section "The
  user-agent line".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.1

  The original test uses invalid user agents (containing spaces). This is a tamed
  version which only tests the case insensitivity, as the name suggests. Also see
  test "GoogleOnly_AcceptUserAgentUpToFirstSpace".
  """
  test "TAMED-ID_UserAgentValueCaseInsensitive" do
    assert :ok = Cache.fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_upper", name: TestCache)
    robotstxt_upper = Cache.get("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_upper", name: TestCache)
    assert :ok = Cache.fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_lower", name: TestCache)
    robotstxt_lower = Cache.get("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_lower", name: TestCache)
    assert :ok = Cache.fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_camel", name: TestCache)
    robotstxt_camel = Cache.get("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_camel", name: TestCache)

    url_allowed = "http://foo.bar/x/y"
    url_disallowed = "http://foo.bar/a/b"

    assert :crawlable = Host.crawlable?(robotstxt_upper, "Foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_lower, "Foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_camel, "Foo", url_allowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_upper, "Foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_lower, "Foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_camel, "Foo", url_disallowed)
    assert :crawlable = Host.crawlable?(robotstxt_upper, "foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_lower, "foo", url_allowed)
    assert :crawlable = Host.crawlable?(robotstxt_camel, "foo", url_allowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_upper, "foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_lower, "foo", url_disallowed)
    assert :uncrawlable = Host.crawlable?(robotstxt_camel, "foo", url_disallowed)
  end

  @doc """
  Google specific: accept user-agent value up to the first space. Space is not
  allowed in user-agent values, but that doesn't stop webmasters from using
  them. This is more restrictive than the RFC, since in case of the bad value
  "Googlebot Images" we'd still obey the rules with "Googlebot".
  Extends REP RFC section "The user-agent line"
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.1
  """
  @tag :skip
  test "GoogleOnly_AcceptUserAgentUpToFirstSpace" do
    assert :ok = Cache.fetch("GoogleOnly_AcceptUserAgentUpToFirstSpace-robotstxt", name: TestCache)
    robotstxt = Cache.get("GoogleOnly_AcceptUserAgentUpToFirstSpace-robotstxt", name: TestCache)

    url = "http://foo.bar/x/y"

    assert :crawlable = Host.crawlable?(robotstxt, "Foo", url)
    assert :uncrawlable = Host.crawlable?(robotstxt, "Foo Bar", url)
  end

  @doc """
  If no group matches the user-agent, crawlers must obey the first group with a
  user-agent line with a "*" value, if present. If no group satisfies either
  condition, or no groups are present at all, no rules apply.
  See REP RFC section "The user-agent line".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.1
  """
  @tag :skip
  test "ID_GlobalGroups_Secondary" do
    assert :ok = Cache.fetch("ID_GlobalGroups_Secondary-robotstxt_empty", name: TestCache)
    robotstxt_empty = Cache.get("ID_GlobalGroups_Secondary-robotstxt_empty", name: TestCache)
    assert :ok = Cache.fetch("ID_GlobalGroups_Secondary-robotstxt_global", name: TestCache)
    robotstxt_global = Cache.get("ID_GlobalGroups_Secondary-robotstxt_global", name: TestCache)
    assert :ok = Cache.fetch("ID_GlobalGroups_Secondary-robotstxt_only_specific", name: TestCache)
    robotstxt_only_specific = Cache.get("ID_GlobalGroups_Secondary-robotstxt_only_specific", name: TestCache)

    url = "http://foo.bar/x/y"

    assert :crawlable = Host.crawlable?(robotstxt_empty, "FooBot", url)
    assert :uncrawlable = Host.crawlable?(robotstxt_global, "FooBot", url)
    assert :crawlable = Host.crawlable?(robotstxt_global, "BarBot", url)
    assert :crawlable = Host.crawlable?(robotstxt_only_specific, "QuxBot", url)
  end

  @doc """
  Matching rules against URIs is case sensitive.
  See REP RFC section "The Allow and Disallow lines".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.2
  """
  test "ID_AllowDisallow_Value_CaseSensitive" do
    assert :ok = Cache.fetch("ID_AllowDisallow_Value_CaseSensitive-robotstxt_lowercase_url", name: TestCache)
    robotstxt_lowercase_url = Cache.get("ID_AllowDisallow_Value_CaseSensitive-robotstxt_lowercase_url", name: TestCache)
    assert :ok = Cache.fetch("ID_AllowDisallow_Value_CaseSensitive-robotstxt_uppercase_url", name: TestCache)
    robotstxt_uppercase_url = Cache.get("ID_AllowDisallow_Value_CaseSensitive-robotstxt_uppercase_url", name: TestCache)

    url = "http://foo.bar/x/y"

    assert :uncrawlable = Host.crawlable?(robotstxt_lowercase_url, "FooBot", url)
    assert :crawlable = Host.crawlable?(robotstxt_uppercase_url, "FooBot", url)
  end

  @doc """
  The most specific match found MUST be used. The most specific match is the
  match that has the most octets. In case of multiple rules with the same
  length, the least strict rule must be used.
  See REP RFC section "The Allow and Disallow lines".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.2
  """
  @tag :skip
  test "ID_LongestMatch" do
    url = "http://foo.bar/x/page.html"
    (
      assert :ok = Cache.fetch("ID_LongestMatch-1", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-1", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-2", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-2", name: TestCache)

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/x/")
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-3", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-3", name: TestCache)

      # In case of equivalent disallow and allow patterns for the same
      # user-agent, allow is used.
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-4", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-4", name: TestCache)

      # In case of equivalent disallow and allow patterns for the same
      # user-agent, allow is used.
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-5", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-5", name: TestCache)

      url_a = "http://foo.bar/x"
      url_b = "http://foo.bar/x/"

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url_a)
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url_b)
    )

    (
      assert :ok = Cache.fetch("ID_LongestMatch-6", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-6", name: TestCache)

      # In case of equivalent disallow and allow patterns for the same
      # user-agent, allow is used.
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-7", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-7", name: TestCache)

      # Longest match wins.
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/page.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/page")
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-8", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-8", name: TestCache)

      # Longest match wins.
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/x/y.html")
    )
    (
      assert :ok = Cache.fetch("ID_LongestMatch-9", name: TestCache)
      robotstxt = Cache.get("ID_LongestMatch-9", name: TestCache)

      # Most specific group for FooBot allows implicitly /x/page.
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/x/page")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/y/page")
    )
  end

  @doc """
  Octets in the URI and robots.txt paths outside the range of the US-ASCII
  coded character set, and those in the reserved range defined by RFC3986,
  MUST be percent-encoded as defined by RFC3986 prior to comparison.
  See REP RFC section "The Allow and Disallow lines".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.2

  NOTE: It's up to the caller to percent encode a URL before passing it to the
  parser. Percent encoding URIs in the rules is unnecessary.
  """
  @tag :skip
  test "ID_Encoding" do
    # /foo/bar?baz=http://foo.bar stays unencoded.
    (
      assert :ok = Cache.fetch("ID_Encoding-1", name: TestCache)
      robotstxt = Cache.get("ID_Encoding-1", name: TestCache)

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar?qux=taz&baz=http://foo.bar?tar&par")
    )

    # 3 byte character: /foo/bar/ツ -> /foo/bar/%E3%83%84
    (
      assert :ok = Cache.fetch("ID_Encoding-2", name: TestCache)
      robotstxt = Cache.get("ID_Encoding-2", name: TestCache)

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/%E3%83%84")
      # The parser encodes the 3-byte character, but the URL is not %-encoded.
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/ツ")
    )

    # Percent encoded 3 byte character: /foo/bar/%E3%83%84 -> /foo/bar/%E3%83%84
    (
      assert :ok = Cache.fetch("ID_Encoding-3", name: TestCache)
      robotstxt = Cache.get("ID_Encoding-3", name: TestCache)

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/%E3%83%84")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/ツ")
    )

    # Percent encoded unreserved US-ASCII: /foo/bar/%62%61%7A -> NULL
    # This is illegal according to RFC3986 and while it may work here due to
    # simple string matching, it should not be relied on.
    (
      assert :ok = Cache.fetch("ID_Encoding-4", name: TestCache)
      robotstxt = Cache.get("ID_Encoding-4", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/baz")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/%62%61%7A")
    )
  end

  @doc """
  The REP RFC defines the following characters that have special meaning in
  robots.txt:
  # - inline comment.
  $ - end of pattern.
  * - any number of characters.
  See REP RFC section "Special Characters".
  https://www.rfc-editor.org/rfc/rfc9309.html#section-2.2.3
  """
  @tag :skip
  test "ID_SpecialCharacters" do
    (
      assert :ok = Cache.fetch("ID_SpecialCharacters-1", name: TestCache)
      robotstxt = Cache.get("ID_SpecialCharacters-1", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/quz")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/quz")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo//quz")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bax/quz")
    )
    (
      assert :ok = Cache.fetch("ID_SpecialCharacters-2", name: TestCache)
      robotstxt = Cache.get("ID_SpecialCharacters-2", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/qux")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar/baz")
    )
    (
      assert :ok = Cache.fetch("ID_SpecialCharacters-3", name: TestCache)
      robotstxt = Cache.get("ID_SpecialCharacters-3", name: TestCache)

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/bar")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/foo/quz")
    )
  end

  @doc """
  Google-specific: "index.html" (and only that) at the end of a pattern is
  equivalent to "/".
  """
  @tag :skip
  test "GoogleOnly_IndexHTMLisDirectory" do
    assert :ok = Cache.fetch("GoogleOnly_IndexHTMLisDirectory-robotstxt", name: TestCache)
    robotstxt = Cache.get("GoogleOnly_IndexHTMLisDirectory-robotstxt", name: TestCache)

    # If index.html is allowed, we interpret this as / being allowed too.
    assert :crawlable = Host.crawlable?(robotstxt, "foobot", "http://foo.com/allowed-slash/")
    # Does not exatly match.
    assert :uncrawlable = Host.crawlable?(robotstxt, "foobot", "http://foo.com/allowed-slash/index.htm")
    # Exact match.
    assert :crawlable = Host.crawlable?(robotstxt, "foobot", "http://foo.com/allowed-slash/index.html")
    assert :uncrawlable = Host.crawlable?(robotstxt, "foobot", "http://foo.com/anyother-url")
  end

  @doc """
  Google-specific: long lines are ignored after 8 * 2083 bytes. See comment in
  RobotsTxtParser::Parse().
  """
  @tag :skip
  test "GoogleOnly_LineTooLong" do
    # does not appear relevant
  end

  @doc """
  Test documentation from
  https://developers.google.com/search/reference/robots_txt
  Section "URL matching based on path values".
  """
  @tag :skip
  test "GoogleOnly_DocumentationChecks" do
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-1", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-1", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/salmon.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fishheads")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fishheads/yummy.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.html?id=anything")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/Fish.asp")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/catfish")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/?id=fish")
    )
    # "/fish*" equals "/fish"
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-2", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-2", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/salmon.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fishheads")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fishheads/yummy.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.html?id=anything")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/Fish.bar")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/catfish")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/?id=fish")
    )
    # "/fish/" does not equal "/fish"
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-3", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-3", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/salmon")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/?salmon")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/salmon.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish/?id=anything")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.html")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/Fish/Salmon.html")
    )
    # "/*.php"
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-4", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-4", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/folder/filename.php")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/folder/filename.php?parameters")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar//folder/any.php.file.html")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php/")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/index?f=filename.php/")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/php/")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/index?php")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/windows.PHP")
    )
    # "/*.php$"
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-5", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-5", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/folder/filename.php")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php?parameters")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php/")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename.php5")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/php/")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/filename?php")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/aaaphpaaa")
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar//windows.PHP")
    )
    # "/fish*.php"
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-6", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-6", name: TestCache)

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/bar")

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fish.php")
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/fishheads/catfish.php?parameters")

      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", "http://foo.bar/Fish.PHP")
    )
    # Section "Order of precedence for group-member records".
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-7", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-7", name: TestCache)

      url = "http://example.com/page"
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-8", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-8", name: TestCache)

      url = "http://example.com/folder/page"
      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-9", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-9", name: TestCache)

      url = "http://example.com/page.htm"
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url)
    )
    (
      assert :ok = Cache.fetch("GoogleOnly_DocumentationChecks-10", name: TestCache)
      robotstxt = Cache.get("GoogleOnly_DocumentationChecks-10", name: TestCache)

      url = "http://example.com/"
      url_page = "http://example.com/page.html"

      assert :crawlable = Host.crawlable?(robotstxt, "FooBot", url)
      assert :uncrawlable = Host.crawlable?(robotstxt, "FooBot", url_page)
    )
  end
end
