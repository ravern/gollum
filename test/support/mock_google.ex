defmodule MockGoogle do
  @moduledoc """
  Ported Google robots.txt library tests from
  https://github.com/google/robotstxt/blob/455b1583103d13ad88fe526bc058d6b9f3309215/robots_test.cc

  Mocks Fetcher to deliver robots.txt content for testing.
  """
  def fetch("GoogleOnly_SystemTest-empty", _opts) do
    {:ok, ""}
  end

  def fetch("GoogleOnly_SystemTest-disallow_foobot", _opts) do
    {:ok,
     "user-agent: FooBot\n" <>
       "disallow: /\n"}
  end

  def fetch("ID_LineSyntax_Line-robotstxt_correct", _opts) do
    {:ok,
     "user-agent: FooBot\n" <>
       "disallow: /\n"}
  end

  def fetch("ID_LineSyntax_Line-robotstxt_incorrect", _opts) do
    {:ok,
     "foo: FooBot\n" <>
       "bar: /\n"}
  end

  def fetch("ID_LineSyntax_Line-robotstxt_incorrect_accepted", _opts) do
    {:ok,
     "user-agent FooBot\n" <>
       "disallow /\n"}
  end

  def fetch("ID_LineSyntax_Groups-robotstxt", _opts) do
    {:ok,
     "allow: /foo/bar/\n" <>
       "\n" <>
       "user-agent: FooBot\n" <>
       "disallow: /\n" <>
       "allow: /x/\n" <>
       "user-agent: BarBot\n" <>
       "disallow: /\n" <>
       "allow: /y/\n" <>
       "\n" <>
       "\n" <>
       "allow: /w/\n" <>
       "user-agent: BazBot\n" <>
       "\n" <>
       "user-agent: FooBot\n" <>
       "allow: /z/\n" <>
       "disallow: /\n"}
  end

  def fetch("ID_LineSyntax_Groups_OtherRules-sitemap", _opts) do
    {:ok,
     "User-agent: BarBot\n" <>
          "Sitemap: https://foo.bar/sitemap\n" <>
          "User-agent: *\n" <>
          "Disallow: /\n"}
  end

  def fetch("ID_LineSyntax_Groups_OtherRules-invalid_line", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Invalid-Unknown-Line: unknown\n" <>
          "User-agent: *\n" <>
          "Disallow: /\n"}
  end

  def fetch("ID_REPLineNamesCaseInsensitive-robotstxt_upper", _opts) do
    {:ok,
        "USER-AGENT: FooBot\n" <>
        "ALLOW: /x/\n" <>
        "DISALLOW: /\n"}
  end

  def fetch("ID_REPLineNamesCaseInsensitive-robotstxt_lower", _opts) do
    {:ok,
        "user-agent: FooBot\n" <>
        "allow: /x/\n" <>
        "disallow: /\n"}
  end

  def fetch("ID_REPLineNamesCaseInsensitive-robotstxt_camel", _opts) do
    {:ok,
        "uSeR-aGeNt: FooBot\n" <>
        "AlLoW: /x/\n" <>
        "dIsAlLoW: /\n"}
  end

  def fetch("ID_UserAgentValueCaseInsensitive-robotstxt_upper", _opts) do
    {:ok,
        "User-Agent: FOO BAR\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("ID_UserAgentValueCaseInsensitive-robotstxt_lower", _opts) do
    {:ok,
        "User-Agent: foo bar\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("ID_UserAgentValueCaseInsensitive-robotstxt_camel", _opts) do
    {:ok,
        "User-Agent: FoO bAr\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_upper", _opts) do
    {:ok,
        "User-Agent: FOO\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_lower", _opts) do
    {:ok,
        "User-Agent: foo\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("TAMED-ID_UserAgentValueCaseInsensitive-robotstxt_camel", _opts) do
    {:ok,
        "User-Agent: FoO\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("GoogleOnly_AcceptUserAgentUpToFirstSpace-robotstxt", _opts) do
    {:ok,
        "User-Agent: *\n" <>
        "Disallow: /\n" <>
        "User-Agent: Foo Bar\n" <>
        "Allow: /x/\n" <>
        "Disallow: /\n"}
  end

  def fetch("ID_GlobalGroups_Secondary-robotstxt_empty", _opts) do
    {:ok, ""}
  end

  def fetch("ID_GlobalGroups_Secondary-robotstxt_global", _opts) do
    {:ok,
        "user-agent: *\n" <>
        "allow: /\n" <>
        "user-agent: FooBot\n" <>
        "disallow: /\n"}
  end

  def fetch("ID_GlobalGroups_Secondary-robotstxt_only_specific", _opts) do
    {:ok,
        "user-agent: FooBot\n" <>
        "allow: /\n" <>
        "user-agent: BarBot\n" <>
        "disallow: /\n" <>
        "user-agent: BazBot\n" <>
        "disallow: /\n"}
  end

  def fetch("ID_AllowDisallow_Value_CaseSensitive-robotstxt_lowercase_url", _opts) do
    {:ok,
        "user-agent: FooBot\n" <>
        "disallow: /x/\n"}
  end

  def fetch("ID_AllowDisallow_Value_CaseSensitive-robotstxt_uppercase_url", _opts) do
    {:ok,
        "user-agent: FooBot\n" <>
        "disallow: /X/\n" }
  end

  def fetch("ID_LongestMatch-1", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /x/page.html\n" <>
          "allow: /x/\n"}
  end

  def fetch("ID_LongestMatch-2", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /x/page.html\n" <>
          "disallow: /x/\n"}
  end

  def fetch("ID_LongestMatch-3", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: \n" <>
          "allow: \n"}
  end

  def fetch("ID_LongestMatch-4", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /\n"}
  end

  def fetch("ID_LongestMatch-5", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /x\n" <>
          "allow: /x/\n"}
  end

  def fetch("ID_LongestMatch-6", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /x/page.html\n" <>
          "allow: /x/page.html\n"}
  end

  def fetch("ID_LongestMatch-7", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /page\n" <>
          "disallow: /*.html\n"}
  end

  def fetch("ID_LongestMatch-8", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /x/page.\n" <>
          "disallow: /*.html\n"}
  end

  def fetch("ID_LongestMatch-9", _opts) do
    {:ok,
          "User-agent: *\n" <>
          "Disallow: /x/\n" <>
          "User-agent: FooBot\n" <>
          "Disallow: /y/\n"}
  end

  def fetch("ID_Encoding-1", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /\n" <>
          "Allow: /foo/bar?qux=taz&baz=http://foo.bar?tar&par\n"}
  end

  def fetch("ID_Encoding-2", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /\n" <>
          "Allow: /foo/bar/ツ\n"}
  end

  def fetch("ID_Encoding-3", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /\n" <>
          "Allow: /foo/bar/%E3%83%84\n"}
  end

  def fetch("ID_Encoding-4", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /\n" <>
          "Allow: /foo/bar/%62%61%7A\n"}
  end

  def fetch("ID_SpecialCharacters-1", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /foo/bar/quz\n" <>
          "Allow: /foo/*/qux\n"}
  end

  def fetch("ID_SpecialCharacters-2", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "Disallow: /foo/bar$\n" <>
          "Allow: /foo/bar/qux\n"}
  end

  def fetch("ID_SpecialCharacters-3", _opts) do
    {:ok,
          "User-agent: FooBot\n" <>
          "# Disallow: /\n" <>
          "Disallow: /foo/quz#qux\n" <>
          "Allow: /\n"}
  end

  def fetch("GoogleOnly_IndexHTMLisDirectory-robotstxt", _opts) do
    {:ok,
        "User-Agent: *\n" <>
        "Allow: /allowed-slash/index.html\n" <>
        "Disallow: /\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-1", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /fish\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-2", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /fish*\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-3", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /fish/\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-4", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /*.php\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-5", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /*.php$\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-6", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "disallow: /\n" <>
          "allow: /fish*.php\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-7", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /p\n" <>
          "disallow: /\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-8", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /folder\n" <>
          "disallow: /folder\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-9", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /page\n" <>
          "disallow: /*.htm\n"}
  end

  def fetch("GoogleOnly_DocumentationChecks-10", _opts) do
    {:ok,
          "user-agent: FooBot\n" <>
          "allow: /$\n" <>
          "disallow: /\n"}
  end
end
