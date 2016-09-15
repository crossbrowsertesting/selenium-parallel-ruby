# Getting started: http://docs.seleniumhq.org/docs/03_webdriver.jsp
# API details: https://github.com/SeleniumHQ/selenium#selenium

# The gem "Rest-CLient" is highly recommended for making API calls
# install it with "gem install rest-client"

# For creating unit tests, we recommend test-unit
# Install it with "gem install test-unit"

require "selenium-webdriver"
require "rest-client"
require "test-unit"

class LoginFormTest < Test::Unit::TestCase
	def test_login_form_test
		begin
			username = "you%40yourcompany.com"
			authkey = "12345"

			caps = Selenium::WebDriver::Remote::Capabilities.new

			caps["name"] = "Login Form - Selenium Test Example"
			caps["build"] = "1.0"
			caps["browser_api_name"] = "Chrome53"
			caps["os_api_name"] = "Win8"
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
		    driver.manage.window.maximize

		    puts "Loading URL"
		    driver.navigate.to("http://crossbrowsertesting.github.io/login-form.html")

		    # start login process by entering username
		    puts "Entering username"
		    driver.find_element(:name, "username").send_keys("tester@crossbrowsertesting.com")

		    # then we'll enter the password
		    puts "Entering password"
		    driver.find_element(:name, "password").send_keys("test123")

		    # then we'll click the login button
		    puts "Logging in"
		    driver.find_element(:css, "div.form-actions > button").click

		    # let's wait here to ensure that the page is fully loaded before we move forward
		    wait = Selenium::WebDriver::Wait.new(:timout => 10)
		    wait.until {
		    	driver.find_element(:xpath, "//*[@id=\"logged-in-message\"]/h2")
		    }

		    # if we passed the login, then we should see some welcomeText
		    welcomeText = driver.find_element(:xpath, "//*[@id=\"logged-in-message\"]/h2").text
		    assert_equal("Welcome tester@crossbrowsertesting.com", welcomeText)

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
