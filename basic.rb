# Getting started: http://docs.seleniumhq.org/docs/03_webdriver.jsp
# API details: https://github.com/SeleniumHQ/selenium#selenium

# The gem "Rest-CLient" is highly recommended for making API calls
# install it with "gem install rest-client"

# For creating unit tests, we recommend test-unit
# Install it with "gem install test-unit"

require "selenium-webdriver"
require "rest-client"
require "test-unit"

class BasicTest < Test::Unit::TestCase
    def test_basic_test
        begin
            
            username = "you%40yourcompany.com"
            authkey = "12345"

            caps = Selenium::WebDriver::Remote::Capabilities.new

            caps["name"] = "Basic Example"
            caps["build"] = "1.0"
            caps["browserName"] = "Chrome"      # pulls latest version by default
            caps["platform"] = "Windows 8"      # to specify version, add caps["version"] = "desired version"
            caps["screen_resolution"] = "1024x768"
            caps["record_video"] = "true"
            caps["record_network"] = "true"

            driver = Selenium::WebDriver.for(:remote,
            :url => "http://#{username}:#{authkey}@hub.crossbrowsertesting.com:80/wd/hub",
            :desired_capabilities => caps)

            session_id = driver.session_id

            score = "pass"
            cbt_api = CBT_API.new
            # maximize the window - DESKTOPS ONLY
            # driver.manage.window.maximize

            puts "Loading URL"
            driver.navigate.to("http://crossbrowsertesting.github.io/selenium_example_page.html")

            expected_title = "Selenium Test Example Page"

            puts "Grabbing title"
            actual_title = driver.title

            # we'll assert that the title is what we want
            assert_equal(expected_title, actual_title)

            puts "Taking Snapshot"
            cbt_api.getSnapshot(session_id)
            cbt_api.setScore(session_id, "pass")

        rescue Exception => ex
            puts ("#{ex.class}: #{ex.message}")
            cbt_api.setScore(session_id, "fail")
        ensure     
            driver.quit
        end
    end
end

class CBT_API
    @@username = 'you%40yourcompany.com'
    @@authkey = '12345'
    @@BaseUrl =   "https://#{@@username}:#{@@authkey}@crossbrowsertesting.com/api/v3"
    def getSnapshot(sessionId)
        # this returns the the snapshot's "hash" which is used in the
        # setDescription function
        response = RestClient.post(@@BaseUrl + "/selenium/#{sessionId}/snapshots",
            "selenium_test_id=#{sessionId}")
        snapshotHash = /(?<="hash": ")((\w|\d)*)/.match(response)[0]
        return snapshotHash
    end

    def setDescription(sessionId, snapshotHash, description)
        response = RestClient.put(@@BaseUrl + "/selenium/#{sessionId}/snapshots/#{snapshotHash}",
            "description=#{description}")
    end

    def setScore(sessionId, score)
        # valid scores are 'pass', 'fail', and 'unset'
        response = RestClient.put(@@BaseUrl + "/selenium/#{sessionId}",
            "action=set_score&score=#{score}")
    end
end
